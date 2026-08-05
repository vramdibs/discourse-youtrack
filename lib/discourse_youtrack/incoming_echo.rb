# frozen_string_literal: true

module DiscourseYoutrack
  module IncomingEcho
    def self.destroy_if_echo!(post)
      return false unless echo?(post)

      PostDestroyer.new(Discourse.system_user, post).destroy
      true
    rescue => e
      Rails.logger.warn(
        "[discourse-youtrack] failed to destroy pingback echo post=#{post.id}: #{e.class}: #{e.message}",
      )
      false
    end

    def self.echo?(post)
      return false unless post.via_email ||
                          post.user&.username == DiscourseYoutrack::YOUTRACK_BOT_USERNAME

      PingbackMarker.present_in?(post.raw) || PingbackMarker.present_in?(post.cooked)
    end
  end
end
