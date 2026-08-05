# frozen_string_literal: true

module DiscourseYoutrack
  class IssueIdResolver
    TOPIC_CF = "discourse_youtrack_issue_id"

    def self.issue_id_from_text(text)
      return nil if text.blank?

      host = base_host
      return nil if host.blank?

      pattern = /#{Regexp.escape(host)}\/issue\/([A-Z]+-\d+)/i
      match = text.match(pattern)
      match&.[](1)&.upcase
    end

    def self.read_cached(topic)
      topic.custom_fields[TOPIC_CF]
    rescue HasCustomFields::NotPreloadedError
      TopicCustomField.find_by(topic_id: topic.id, name: TOPIC_CF)&.value
    end

    # Full resolve (topic view, jobs). Do not call from topic_list_item serializers:
    # list topics use a PreloadedProxy and forbid unlisted custom field access.
    def self.resolve_for_topic(topic)
      cached = read_cached(topic)
      return cached if cached.present?

      first_post = topic.posts.find_by(post_number: 1)
      return nil unless first_post

      id =
        issue_id_from_text(first_post.cooked) || issue_id_from_text(first_post.raw)
      if id.present?
        topic.custom_fields[TOPIC_CF] = id
        topic.save_custom_fields
      end

      id
    end

    def self.base_host
      url = SiteSetting.discourse_youtrack_base_url.to_s.strip
      return nil if url.blank?

      URI.parse(url).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
