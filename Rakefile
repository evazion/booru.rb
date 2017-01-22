require "bundler/gem_tasks"
require "active_support"
require "active_support/core_ext"
require "pry"
require "time"

date = Time.now.utc.iso8601

def bash(command)
  puts command + "\n"
  system "/usr/bin/env", "bash", "-c", command
end

task default: :install

namespace :dump do
  resources = {
    # artist_commentaries_versions: %i(artist_commentaries posts users),
    # artist_versions: %i(artists users),
    # note_versions: %i(notes posts users),
    # pool_versions: %i(pools posts users),
    # post_versions: %i(posts tags users),
    # wiki_page_versions: %i(users wiki_pages),

    artist_commentaries: %i(posts users),
    artists: %i(tags users),
    bans: %i(users),
    bulk_update_requests: %i(forum_topics tags tag_aliases tag_implications users),
    comments: %i(posts users),
    forum_posts: %i(forum_topics users),
    forum_topics: %i(users),
    mod_actions: %i(users),
    notes: %i(posts users),
    pools: %i(posts users),
    post_appeals: %i(posts users),
    post_flags: %i(posts users),
    tag_aliases: %i(forum_topics tags users),
    tag_implications: %i(forum_topics tags users),
    uploads: %i(posts tags users),
    user_feedbacks: %i(users),
    wiki_pages: %i(tags users),
    posts: %i(tags users),
    user_name_change_requests: %i(users),
    tags: [],
    users: [],
  }

  prereqs = Hash.new { |h, k| h[k] = [] }
  resources.each { |k, v| v.each { |d| prereqs[d] << k } }

  desc "Export everything to gs://evazion/danbooru/#{date}/"
  task :all => resources.keys

  resources.each do |name, dependencies|
    url = "gs://evazion/danbooru/#{date}/#{name}.json.xz"

    desc "Export /#{name}.json to #{url}"
    task name do |t|
    # task name => prereqs.fetch(name, []) do |t|
    # deftask.call name => dependencies do |t|
      raise "$BOORU_SITE not configured." if ENV["BOORU_SITE"].blank?
      raise "$BOORU_LOGIN not configured." if ENV["BOORU_LOGIN"].blank?
      raise "$BOORU_API_KEY not configured." if ENV["BOORU_API_KEY"].blank?

      # puts name
      sh "booru #{name} index 2> errors.#{name}.json | xz -5 | gsutil cp - #{url}"
      sh "gsutil acl ch -u AllUsers:R #{url}"
    end
  end
end
