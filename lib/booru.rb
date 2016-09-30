require "faraday"
require "json"

class Booru
  attr_reader :site, :login, :api_key, :ssl, :timeout
  attr_reader :base_url, :conn
  attr_reader :posts, :post_versions, :tags, :users, :user_feedbacks, :comments

  def initialize(site, login: nil, api_key: nil, ssl: false, timeout: 300)
    @site, @login, @api_key, @ssl, @timeout = site, login, api_key, ssl, timeout
    @base_url = (ssl ? "https://" : "http://") + @site

    @conn = Faraday.new(url: @base_url) do |f|
      f.adapter :net_http_persistent
    end

    @posts = Resource.new(self, "posts")
    @post_versions = Resource.new(self, "post_versions")
    @tags = Resource.new(self, "tags")
    @users = Resource.new(self, "users")
    @comments = Comments.new(self)
  end

  def params
    @params ||= {}
    @params[:login] ||= login
    @params[:api_key] ||= api_key
    @params
  end
end

class Danbooru < Booru
  def initialize(site: "danbooru.donmai.us", **args)
    super(site, **args)
  end
end

class Resource
  class Error < StandardError; end

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

    raise Error, response unless response.success?
    JSON.parse(response.body)
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
