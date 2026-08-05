# frozen_string_literal: true

module ::Jobs
  class DeleteYoutrackComment < ::Jobs::Base
    sidekiq_options retry: 3

    COMMENT_ID_CF = DiscourseYoutrack::COMMENT_ID_CF
    SYNC_STATUS_CF = DiscourseYoutrack::SYNC_STATUS_CF

    def execute(args)
      return unless plugin_enabled?

      comment_id = args["comment_id"].presence
      issue_id = args["issue_id"].presence
      return if comment_id.blank?

      if issue_id.blank?
        post = Post.with_deleted.find_by(id: args["post_id"])
        issue_id = DiscourseYoutrack::IssueIdResolver.resolve_for_topic(post.topic) if post&.topic
      end
      return if issue_id.blank?

      DiscourseYoutrack::YoutrackClient.delete_comment(issue_id, comment_id)

      post = Post.with_deleted.find_by(id: args["post_id"])
      if post
        post.custom_fields[SYNC_STATUS_CF] = "deleted"
        post.custom_fields[COMMENT_ID_CF] = nil
        post.save_custom_fields
      end
    rescue DiscourseYoutrack::YoutrackClient::ApiError => e
      Rails.logger.warn(
        "[discourse-youtrack] delete comment failed issue=#{issue_id} comment=#{comment_id} code=#{e.code}",
      )
    end

    private

    def plugin_enabled?
      SiteSetting.discourse_youtrack_enabled &&
        SiteSetting.discourse_youtrack_base_url.present? &&
        SiteSetting.discourse_youtrack_api_token.present?
    end
  end
end
