# frozen_string_literal: true

module DiscourseYoutrack
  class YoutrackClient
    class ApiError < StandardError
      attr_reader :code, :status, :body

      def initialize(code, status, body)
        @code = code
        @status = status
        @body = body
        super("#{code} (#{status})")
      end
    end

    def self.post_comment(issue_id, text)
      new.post_comment(issue_id, text)
    end

    def self.delete_comment(issue_id, comment_id)
      new.delete_comment(issue_id, comment_id)
    end

    def post_comment(issue_id, text)
      base = SiteSetting.discourse_youtrack_base_url.to_s.strip
      token = SiteSetting.discourse_youtrack_api_token

      uri = URI.join(base + "/", "api/issues/#{issue_id}/comments")
      response =
        Excon.post(
          uri.to_s,
          headers: auth_headers(token),
          body: { text: text, usesMarkdown: true }.to_json,
          connect_timeout: 10,
          read_timeout: 30,
        )

      case response.status
      when 200
        json = JSON.parse(response.body)
        { id: json["id"] }
      when 401, 403
        raise ApiError.new("auth_failed", response.status, response.body)
      when 404
        raise ApiError.new("issue_not_found", response.status, response.body)
      else
        raise ApiError.new("upstream_error", response.status, response.body)
      end
    end

    def delete_comment(issue_id, comment_id)
      base = SiteSetting.discourse_youtrack_base_url.to_s.strip
      token = SiteSetting.discourse_youtrack_api_token

      uri = URI.join(base + "/", "api/issues/#{issue_id}/comments/#{comment_id}")
      response =
        Excon.delete(
          uri.to_s,
          headers: auth_headers(token),
          connect_timeout: 10,
          read_timeout: 30,
        )

      case response.status
      when 200, 204
        { ok: true }
      when 404
        # Already gone in YouTrack — treat as success for Discourse soft-delete sync.
        { ok: true, missing: true }
      when 401, 403
        raise ApiError.new("auth_failed", response.status, response.body)
      else
        raise ApiError.new("upstream_error", response.status, response.body)
      end
    end

    private

    def auth_headers(token)
      {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
      }
    end
  end
end
