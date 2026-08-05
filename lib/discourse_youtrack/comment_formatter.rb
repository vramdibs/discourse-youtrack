# frozen_string_literal: true

module DiscourseYoutrack
  class CommentFormatter
    def self.format(post)
      user = post.user
      display_name = user&.name.presence || user&.username || "unknown"
      body = post.raw.to_s.strip
      url = PingbackMarker.append_to_url(post.full_url, post.id)
      marker = PingbackMarker.html_comment(post.id)

      "#{display_name} в Discourse:\n\n#{body}\n\n[ответ в Discourse](#{url})\n\n#{marker}"
    end
  end
end
