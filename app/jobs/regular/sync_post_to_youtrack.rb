# frozen_string_literal: true

module ::Jobs
  class SyncPostToYoutrack < ::Jobs::Base
    sidekiq_options retry: 3

    SYNC_REQUESTED_CF = "discourse_youtrack_sync_requested"
    SYNC_STATUS_CF = "discourse_youtrack_sync_status"
    SYNC_ERROR_CF = "discourse_youtrack_sync_error"
    COMMENT_ID_CF = "discourse_youtrack_comment_id"
    YOUTRACK_BOT_USERNAME = "YouTrack"

    def execute(args)
      return unless plugin_enabled?

      post = Post.find_by(id: args["post_id"])
      return unless post
      return unless sync_requested?(post)
      return if skip_post?(post)

      issue_id = DiscourseYoutrack::IssueIdResolver.resolve_for_topic(post.topic)
      unless issue_id
        mark_error(post, "issue_not_found")
        return
      end

      text = DiscourseYoutrack::CommentFormatter.format(post)
      result = DiscourseYoutrack::YoutrackClient.post_comment(issue_id, text)

      post.custom_fields[SYNC_STATUS_CF] = "ok"
      post.custom_fields[SYNC_ERROR_CF] = nil
      post.custom_fields[COMMENT_ID_CF] = result[:id]
      post.save_custom_fields
    rescue DiscourseYoutrack::YoutrackClient::ApiError => e
      mark_error(post, e.code)
    end

    private

    def plugin_enabled?
      SiteSetting.discourse_youtrack_enabled &&
        SiteSetting.discourse_youtrack_base_url.present? &&
        SiteSetting.discourse_youtrack_api_token.present?
    end

    def sync_requested?(post)
      post.custom_fields[SYNC_REQUESTED_CF].to_s == "true" ||
        post.custom_fields[SYNC_REQUESTED_CF] == true
    end

    def skip_post?(post)
      post.post_number == 1 || post.via_email || post.user&.username == YOUTRACK_BOT_USERNAME
    end

    def mark_error(post, code)
      post.custom_fields[SYNC_STATUS_CF] = "error"
      post.custom_fields[SYNC_ERROR_CF] = code
      post.save_custom_fields

      MessageBus.publish(
        "/discourse-youtrack/post/#{post.id}",
        { status: "error", error: code },
        user_ids: [post.user_id],
      )
    end
  end
end
