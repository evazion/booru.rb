require "faraday"
require "json"

class Booru
  # admin explore maintenance
  # comments
  Resources = %w(
    advertisements
    api_keys
    artist_commentaries
    artist_commentary_versions
    artist_versions
    artists
    bans
    bulk_update_requests
    counts
    delayed_jobs
    dmails
    dtext_preview
    favorite_groups
    favorites
    forum_posts
    forum_topics
    ip_bans
    iqdb_queries
    janitor_trials
    meta_searches
    mod_actions
    news_updates
    note_previews
    note_versions
    notes
    pool_element
    pool_versions
    pools
    post_appeals
    post_flags
    post_versions
    posts
    related_tag
    reports
    saved_search_category_change
    saved_searches
    session
    source
    static
    super_voters
    tag_alias_request
    tag_aliases
    tag_implication_request
    tag_implications
    tag_subscriptions
    tags
    uploads
    user_feedbacks
    user_name_change_requests
    user_revert
    user_upgrade
    users
    wiki_page_versions
    wiki_pages
  )

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

  # Effectively does `def posts; @posts ||= Resource.new(self, "posts"); end`
  # for every resource.
  Resources.each do |name|
    define_method(name) do
      instance_variable_set(
        "@#{name}",
        instance_variable_get("@#{name}") || Booru::Resource.new(self, name)
      )
    end
  end
end

class Danbooru < Booru
  def initialize(site: "danbooru.donmai.us", **args)
    super(site, **args)
  end
end

class Booru::Resource
  class Error < Booru::Error; end

  include Enumerable
  attr_reader :booru, :resource

  def initialize(booru, resource)
    @booru, @resource = booru, resource
  end

  def show(id)
    response = booru.conn.get("/#{@resource}/#{id}.json")

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
    # XXX set size of collection
    return enum_for(__method__) unless block_given?

    id, max_limit, code, url = from - 1, limit, nil, nil

    loop do
      response = booru.conn.get("/#{@resource}.json", { page: "a#{id}", limit: limit })

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

class Booru::Artists < Booru::Resource
  def initialize(booru)
    super(booru, "artists")
  end

  def banned
    response = booru.conn.get("/#{@resource}/banned.json")

    raise Error, response unless response.success?
    JSON.parse(response.body)
  end
end
