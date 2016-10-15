require "faraday"
require "json"

class Booru
  class Error < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
      super(self.message)
    end

    def message
      "#{response.headers["status"]}: #{response.env.method.upcase} #{response.env.url.to_s}"
    end
  end

  attr_reader :site, :login, :api_key, :ssl, :timeout
  attr_reader :base_url, :conn

  def initialize(site, login: nil, api_key: nil, ssl: false, timeout: 300)
    @site, @login, @api_key, @ssl, @timeout = site, login, api_key, ssl, timeout
    @base_url = (ssl ? "https://" : "http://") + @site

    @conn = Faraday.new(url: @base_url) do |f|
      f.adapter :net_http_persistent
    end

    @conn.basic_auth(login, api_key)
  end

  def posts; @posts ||= Resource.new(self, "posts"); end
  def artists; @artists ||= Artists.new(self); end
  def artist_commentaries; @artist_commentaries ||= Resource.new(self, "artist_commentaries"); end
  def bulk_update_requests; @bulk_update_requests ||= Resource.new(self, "bulk_update_requests"); end
  def comments; @comments ||= Comments.new(self); end
  def notes; @notes ||= Resource.new(self, "notes"); end
  def pools; @pools ||= Resource.new(self, "pools"); end
  def post_appeals; @post_appeals ||= Resource.new(self, "post_appeals"); end
  def post_flags; @post_flags ||= Resource.new(self, "post_flags"); end
  def tag_aliases; @tag_aliases ||= Resource.new(self, "tag_aliases"); end
  def tag_implications; @tag_implications ||= Resource.new(self, "tag_implications"); end
  def uploads; @uploads ||= Resource.new(self, "uploads"); end
  def user_feedbacks; @user_feedbacks ||= Resource.new(self, "user_feedbacks"); end
  def wiki_pages; @wiki_pages ||= Resource.new(self, "wiki_pages"); end
  def forum_topics; @forum_topics ||= Resource.new(self, "forum_topics"); end
  def forum_posts; @forum_posts ||= Resource.new(self, "forum_posts"); end
  def tags; @tags ||= Resource.new(self, "tags"); end
  def users; @users ||= Resource.new(self, "users"); end
  def posts; @posts ||= Resource.new(self, "posts"); end

  def post_versions; @post_versions ||= Resource.new(self, "post_versions"); end
  def note_versions; @note_versions ||= Resource.new(self, "note_versions"); end
  def wiki_page_versions; @wiki_page_versions ||= Resource.new(self, "wiki_page_versions"); end
  def pool_versions; @pool_versions ||= Resource.new(self, "pool_versions"); end
  def artist_commentary_versions; @artist_commentary_versions ||= Resource.new(self, "artist_commentary_versions"); end

  def params
    @params ||= {}
    @params
  end
end

class Danbooru < Booru
  def initialize(site: "danbooru.donmai.us", **args)
    super(site, **args)
  end
end

class Resource
  class Error < Booru::Error; end

  include Enumerable
  attr_reader :booru, :resource, :params

  def initialize(booru, resource, params = {})
    @booru, @resource, @params = booru, resource, params
  end

  def params
    @booru.params.merge(@params)
  end

  def show(id)
    response = @booru.conn.get("/#{@resource}/#{id}.json", params.merge({ id: id }))

    return JSON.parse(response.body), (response.success? ? nil : Error.new(response))
  end

  def on_response(status, records, id, limit, code, url)
    state = {
      status: status,
      code: code,
      id: id,
      limit: limit,
      url: url,
    }

    state.merge!({
      first: records.first["id"],
      last: records.last["id"],
      missing: (records.first["id"] .. records.last["id"]).to_a - records.map { |r| r["id"] }
    }) if records.size > 0

    warn state.to_json
  end

  def each(from: 1, to: 1_000_000_000, limit: 1000)
    id, max_limit, code, url = from - 1, limit, nil, nil

    loop do
      response = @booru.conn.get(
        "/#{@resource}.json",
        params.merge({ page: "a#{id}", limit: limit })
      )

      code = response.env.status
      url = response.env.url

      if response.success? && code == 200
        records = JSON.parse(response.body)
        records = records.reverse.reject { |r| r["id"] > to }

        return self if records.size == 0

        records.each { |r| yield r }
        on_response(:success, records, id, limit, code, url)

        limit = [2 * limit, max_limit].min
        id = records.map { |r| r["id"] }.max
      elsif code == 500 && limit > 1
        on_response(:fail, [], id, limit, code, url)

        limit = 1
      elsif code == 500 && limit == 1
        on_response(:ignore, [], id, limit, code, url)

        limit = max_limit
        id += 1
      else
        on_response(:exception, [], id, limit, code, url)
        raise Error
      end
    end
  end
end

class Artists < Resource
  def initialize(booru)
    super(booru, "artists")
  end

  def banned
    response = @booru.conn.get("/#{@resource}/banned.json", params)

    raise Error, response unless response.success?
    JSON.parse(response.body)
  end
end

class Comments < Resource
  def initialize(booru)
    super(booru, "comments", group_by: "comment")
  end
end
