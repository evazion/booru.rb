# usage:
#   rake export:users
#   rake truncate:users
#   rake import:users
#   rake -T
#
# requirements: bash, wget, jq, xz.

require "bundler/gem_tasks"
require "active_support"
require "active_support/core_ext"
require "pry"
require "time"

db = "danbooru2"
schema = "public"
date = ENV["DATE"] || Time.now.utc.beginning_of_day.iso8601

resources = {
  artist_commentary_versions: %w(id post_id updater_id updater_ip_addr original_title original_description translated_title translated_description created_at updated_at),
  artist_versions: %w(id artist_id name updater_id updater_ip_addr is_active other_names group_name url_string is_banned created_at updated_at),
  note_versions: %w(id note_id post_id updater_id updater_ip_addr x y width height is_active body created_at updated_at version),
  pool_versions: %w(),
  post_versions: %w(id created_at updater_at post_id tags rating parent_id source updater_id updater_ip_addr),
  wiki_page_versions: %w(id wiki_page_id updater_id updater_ip_addr title body is_locked created_at updated_at other_names is_deleted),

  artist_commentaries: %w(id post_id original_title original_description translated_title translated_description created_at updated_at),
  artists: %w(id name creator_id is_active is_banned other_names other_names_index group_name created_at updated_at),
  bans: %w(id user_id reason banner_id expires_at created_at updated_at),
  bulk_update_requests: %w(id user_id forum_topic_id script status created_at updated_at approved_id),
  comments: %w(id post_id creator_id body ip_addr body_index score created_at updated_at updater_id updater_ip_addr do_not_bump_post is_deleted is_sticky),
  forum_posts: %w(id topic_id creator_id updater_id body text_index is_deleted created_at updated_at),
  forum_topics: %w(id creator_id updater_id title response_count is_sticky is_locked is_deleted text_index created_at updated_at category_id min_level),
  mod_actions: %w(id creator_id description created_at updated_at),
  notes: %w(id creator_id post_id x y width height is_active body body_index created_at updated_at version),
  pools: %w(id name creator_id description is_active post_ids post_count is_deleted created_at updated_at category),
  post_appeals: %w(id post_id creator_id creator_ip_addr reason created_at updated_at),
  post_flags: %w(id post_id creator_id creator_ip_addr reason is_resolved created_at updated_at),
  posts: %w(id created_at updated_at up_score down_score score source md5 rating is_note_locked is_rating_locked is_status_locked is_pending is_flagged is_deleted uploader_id uploader_ip_addr approver_id fav_string pool_string last_noted_at last_comment_bumped_at fav_count tag_string tag_index tag_count tag_count_general tag_count_artist tag_count_character tag_count_copyright file_ext file_size image_width image_height parent_id has_children is_banned pixiv_id last_commented_at has_active_children bit_flags),
  tag_aliases: %w(id antecedent_name consequent_name creator_id creator_ip_addr forum_topic_id status created_at updated_at post_count approver_id),
  tag_implications: %w(id antecedent_name consequent_name descendant_names creator_id creator_ip_addr forum_topic_id status created_at updated_at approver_id),
  tags: %w(id name post_count category related_tags related_tags_updated_at created_at updated_at is_locked),
  uploads: %w(id source file_path content_type rating uploader_id uploader_ip_addr tag_string status backtrace post_id md5_confirmation created_at updated_at server parent_id),
  users: %w(id created_at updated_at name password_hash email email_verification_key inviter_id level base_upload_limit last_logged_in_at last_forum_read_at recent_tags post_upload_count post_update_count note_update_count favorite_count comment_threshold default_image_size favorite_tags blacklisted_tags time_zone bcrypt_password_hash per_page custom_style bit_prefs last_ip_addr),
  user_feedback: %w(id user_id creator_id category body created_at updated_at),
  user_name_change_requests: %w(id status user_id approver_id original_name desired_name change_reason rejection_reason created_at updated_at),
  wiki_pages: %w(id creator_id title body body_index is_locked created_at updated_at updater_id other_names other_names_index is_deleted),
}

munge = {
  artist_commentary_versions: %(
    . += { updater_ip_addr: "127.0.0.1" }
  ),
  artist_versions: %(
    . += { updater_ip_addr: "127.0.0.1" }
  ),
  note_versions: %(
    . += { updater_ip_addr: "127.0.0.1" }
  ),
  post_versions: %(
    . += { updater_ip_addr: "127.0.0.1" }
  ),
  wiki_page_versions: %(
    . += { updater_ip_addr: "127.0.0.1" }
  ),
  artists: %(
    .creator_id //= 13
  ),
  comments: %(
    . += { ip_addr: "127.0.0.1", updater_ip_addr: "127.0.0.1" }
  ),
  forum_topics: %(
    .min_level //= 0
  ),
  post_appeals: %(
    . += { creator_ip_addr: "127.0.0.1" }
  ),
  post_flags: %(
    .creator_id //= 13 |
    . += { creator_ip_addr: "127.0.0.1" }
  ),
  posts: %(
    .image_width //= 0 |
    .image_height //= 0 |
    . += { uploader_ip_addr: "127.0.0.1" }
  ),
  tag_aliases: %(
    . += { creator_ip_addr: "127.0.0.1" }
  ),
  tag_implications: %(
    . += { creator_ip_addr: "127.0.0.1" }
  ),
  uploads: %(
    . += { uploader_ip_addr: "127.0.0.1" }
  ),
  users: %(
    . += { favorite_count: 0 } |

    . += { comment_threshold: -1 } |
    . += { default_image_size: "large" } |
    . += { time_zone: "Eastern Time (US & Canada)" } |
    . += { bcrypt_password_hash: "$2a$10$JvzPN5MczNWoYhjw5WxYg.66QNod7Aa7FXkG/9/nnJ5es1WqsA0we" } |
    . += { password_hash: "" } |
    . += { per_page: 20 } |

    . += { favorite_tags: "" } |
    . += { recent_tags: "" } |
    . += { blacklisted_tags: "" } |
    . += { custom_style: "" } |
    . += { last_ip_addr: "127.0.0.1" } |
    . += { last_logged_in_at: null } |
    . += { last_forum_read_at: null } |
    . += { email_verification_key: null } |
    . += { email: null } |
    . += { updated_at: null } |
    . += {
      bit_prefs: (
          (if .is_banned         then 1     else 0 end)
        + (if .can_approve_posts then 8192  else 0 end)
        + (if .can_upload_free   then 16384 else 0 end)
        + (if .is_super_voter    then 65536 else 0 end)
      )
    }
  ),
}

task default: :install

namespace :export do
  desc "Export everything to gs://evazion/danbooru/#{date}/"
  task :all => resources.keys

  resources.each do |name, cols|
    url = "gs://evazion/danbooru/#{date}/#{name}.json.xz"

    desc "Export /#{name}.json to #{url}"
    task name do |t|
      check_credentials!

      bash "booru #{name} index 2> errors.#{name}.json | xz -5 | gsutil cp - #{url}"
      bash "gsutil acl ch -u AllUsers:R #{url}"
    end
  end
end

namespace :import do
  desc "Import everything from gs://evazion/danbooru/#{date}/"
  task :all => resources.keys

  resources.each do |name, cols|
    table = "#{schema}.#{name}"

    #desc "Download gs://evazion/danbooru/#{date}/#{name}.json.xz"
    #file "#{name}.json.xz" do |t|
    #  bash %(wget https://storage.googleapis.com/evazion/danbooru/#{date}/#{name}.json.xz)
    #end

    desc "Import #{name}.json.xz to #{table}"
    # task name => "#{name}.json.xz" do |t|
    task name do |t|
      # - munge the data to satisfy NOT NULL requirements
      # - reorder the columns to match the database order (given in db/structure.sql)
      #   so that `COPY table FROM STDIN` is happy.
      # - convert json to csv for COPY.
      jq = %(
        #{munge[name] || "."} |
        [ #{cols.map { |col| ".#{col}" }.join(", ")} ] |
        @csv
      )

      sql = %Q(
        -- CREATE TABLE IF NOT EXISTS #{table} (LIKE public.#{name} INCLUDING ALL);
        -- UPDATE pg_index SET indislive = FALSE WHERE indrelid = '#{table}'::regclass;
        COPY #{table} FROM STDIN WITH (FORMAT csv);
        -- UPDATE pg_index SET indislive = TRUE WHERE indrelid = '#{table}'::regclass;
        -- REINDEX TABLE #{table};
      )

      bash %(
        curl https://storage.googleapis.com/evazion/danbooru/#{date}/#{name}.json.xz |
        unxz |
        jq -rc '#{jq}' |
        psql '#{db}' -e -c '#{sql}'
      )
    end
  end
end

namespace :truncate do
  desc "Truncate all tables"
  task :truncate => resources.keys

  resources.each do |name, cols|
    table = %("#{schema}"."#{name}")

    desc "TRUNCATE TABLE #{table} RESTART IDENTITY"
    task name do |t|
      bash %(psql '#{db}' -e -c 'TRUNCATE TABLE #{table} RESTART IDENTITY')
    end
  end
end

def check_credentials!
  raise "$BOORU_SITE not configured." if ENV["BOORU_SITE"].blank?
  raise "$BOORU_LOGIN not configured." if ENV["BOORU_LOGIN"].blank?
  raise "$BOORU_API_KEY not configured." if ENV["BOORU_API_KEY"].blank?
end

def bash(command)
  puts command + "\n"
  system "/usr/bin/env", "bash", "-c", command
end
