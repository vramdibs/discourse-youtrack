# frozen_string_literal: true

# name: discourse-youtrack
# about: Integrate Discourse topics and posts with YouTrack issues
# version: 0.2.0
# authors: rapekas
# url: https://github.com/rapekas/discourse-youtrack
# required_version: 3.2.0

enabled_site_setting :discourse_youtrack_enabled

register_asset "stylesheets/common/discourse-youtrack.scss"

module ::DiscourseYoutrack
  PLUGIN_NAME = "discourse-youtrack"

  SYNC_REQUESTED_CF = "discourse_youtrack_sync_requested"
  SYNC_STATUS_CF = "discourse_youtrack_sync_status"
  SYNC_ERROR_CF = "discourse_youtrack_sync_error"
  COMMENT_ID_CF = "discourse_youtrack_comment_id"
  YOUTRACK_BOT_USERNAME = "YouTrack"
end

require_relative "lib/discourse_youtrack/engine"
require_relative "lib/discourse_youtrack/issue_id_resolver"
require_relative "lib/discourse_youtrack/pingback_marker"
require_relative "lib/discourse_youtrack/comment_formatter"
require_relative "lib/discourse_youtrack/youtrack_client"
require_relative "lib/discourse_youtrack/incoming_echo"

after_initialize do
  register_post_custom_field_type(DiscourseYoutrack::SYNC_REQUESTED_CF, :boolean)
  register_post_custom_field_type(DiscourseYoutrack::SYNC_STATUS_CF, :string)
  register_post_custom_field_type(DiscourseYoutrack::SYNC_ERROR_CF, :string)
  register_post_custom_field_type(DiscourseYoutrack::COMMENT_ID_CF, :string)
  register_topic_custom_field_type(DiscourseYoutrack::IssueIdResolver::TOPIC_CF, :string)
  add_preloaded_topic_list_custom_field(DiscourseYoutrack::IssueIdResolver::TOPIC_CF)

  add_permitted_post_create_param(:discourse_youtrack_sync_requested)

  add_to_serializer(:topic_view, :discourse_youtrack_issue_id) do
    DiscourseYoutrack::IssueIdResolver.resolve_for_topic(object.topic)
  end

  # List path: only the preloaded cache. Parsing first post here caused
  # HasCustomFields::NotPreloadedError and N+1 queries on every category page.
  add_to_serializer(:topic_list_item, :discourse_youtrack_issue_id) do
    object.custom_fields[DiscourseYoutrack::IssueIdResolver::TOPIC_CF]
  end

  add_to_serializer(:post, :discourse_youtrack_sync_requested) do
    object.custom_fields[DiscourseYoutrack::SYNC_REQUESTED_CF]
  end

  add_to_serializer(:post, :discourse_youtrack_sync_status) do
    object.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]
  end

  add_to_serializer(:post, :discourse_youtrack_sync_error) do
    object.custom_fields[DiscourseYoutrack::SYNC_ERROR_CF]
  end

  on(:post_created) do |post, opts, _creator|
    next unless SiteSetting.discourse_youtrack_enabled
    next if DiscourseYoutrack::IncomingEcho.destroy_if_echo!(post)

    requested = opts[:discourse_youtrack_sync_requested].to_s == "true"
    next unless requested

    post.custom_fields[DiscourseYoutrack::SYNC_REQUESTED_CF] = true
    post.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF] = "pending"
    post.save_custom_fields

    Jobs.enqueue(:sync_post_to_youtrack, post_id: post.id)
  end

  on(:post_destroyed) do |post, _opts, _user|
    next unless SiteSetting.discourse_youtrack_enabled

    comment_id = post.custom_fields[DiscourseYoutrack::COMMENT_ID_CF].presence
    next if comment_id.blank?

    issue_id = DiscourseYoutrack::IssueIdResolver.resolve_for_topic(post.topic)
    next if issue_id.blank?

    Jobs.enqueue(
      :delete_youtrack_comment,
      post_id: post.id,
      issue_id: issue_id,
      comment_id: comment_id,
    )
  end
end
