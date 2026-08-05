# frozen_string_literal: true

RSpec.describe DiscourseYoutrack::YoutrackClient do
  before do
    enable_current_plugin
    SiteSetting.discourse_youtrack_base_url = "https://youtrack.example.com"
    SiteSetting.discourse_youtrack_api_token = "test-token"
  end

  describe ".post_comment" do
    it "returns the comment id on success" do
      stub_request(:post, "https://youtrack.example.com/api/issues/TDOT-1/comments")
        .with(
          body: { text: "hello", usesMarkdown: true }.to_json,
          headers: {
            "Authorization" => "Bearer test-token",
            "Content-Type" => "application/json",
          },
        )
        .to_return(status: 200, body: { id: "comment-42" }.to_json)

      result = described_class.post_comment("TDOT-1", "hello")
      expect(result[:id]).to eq("comment-42")
    end

    it "raises ApiError for 404" do
      stub_request(:post, "https://youtrack.example.com/api/issues/MISSING-1/comments")
        .to_return(status: 404, body: "not found")

      expect { described_class.post_comment("MISSING-1", "hello") }.to raise_error(
        DiscourseYoutrack::YoutrackClient::ApiError,
      ) do |error|
        expect(error.code).to eq("issue_not_found")
      end
    end
  end

  describe ".delete_comment" do
    it "returns ok on 200" do
      stub_request(:delete, "https://youtrack.example.com/api/issues/TDOT-1/comments/c-1")
        .to_return(status: 200, body: "")

      expect(described_class.delete_comment("TDOT-1", "c-1")).to eq({ ok: true })
    end

    it "treats 404 as already deleted" do
      stub_request(:delete, "https://youtrack.example.com/api/issues/TDOT-1/comments/c-1")
        .to_return(status: 404, body: "gone")

      expect(described_class.delete_comment("TDOT-1", "c-1")).to eq({ ok: true, missing: true })
    end
  end
end
