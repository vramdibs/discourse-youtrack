# frozen_string_literal: true

module DiscourseYoutrack
  class PingbackMarker
    QUERY_KEY = "discourse_youtrack_pingback"
    HTML_PATTERN = /<!--\s*discourse-youtrack-pingback:(\d+)\s*-->/i
    QUERY_PATTERN = /(?:\?|&)discourse_youtrack_pingback=(\d+)/i
    ANY_PATTERN = /discourse[-_]youtrack[-_]pingback[=:](\d+)/i

    def self.html_comment(post_id)
      "<!-- discourse-youtrack-pingback:#{post_id} -->"
    end

    def self.append_to_url(url, post_id)
      return url if url.blank? || post_id.blank?

      separator = url.include?("?") ? "&" : "?"
      "#{url}#{separator}#{QUERY_KEY}=#{post_id}"
    end

    def self.present_in?(text)
      text.to_s.match?(HTML_PATTERN) || text.to_s.match?(QUERY_PATTERN) ||
        text.to_s.match?(ANY_PATTERN)
    end

    def self.post_id_from(text)
      text = text.to_s
      match = text.match(HTML_PATTERN) || text.match(QUERY_PATTERN) || text.match(ANY_PATTERN)
      match&.[](1)&.to_i
    end
  end
end
