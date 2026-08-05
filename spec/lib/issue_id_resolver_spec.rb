# frozen_string_literal: true

require "rails_helper"

describe DiscourseYoutrack::IssueIdResolver do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:first_post) { Fabricate(:post, topic: topic, post_number: 1) }

  before do
    enable_current_plugin
    SiteSetting.discourse_youtrack_enabled = true
    SiteSetting.discourse_youtrack_base_url = "https://youtrack.example.com"
    SiteSetting.discourse_youtrack_api_token = "test-token"
  end

  describe ".issue_id_from_text" do
    it "extracts id from http link" do
      html = '<a href="http://youtrack.example.com/issue/TDOT-437">TDOT-437</a>'
      expect(described_class.issue_id_from_text(html)).to eq("TDOT-437")
    end

    it "extracts id from https link" do
      html = "https://youtrack.example.com/issue/tdot-99"
      expect(described_class.issue_id_from_text(html)).to eq("TDOT-99")
    end

    it "returns nil when host does not match" do
      expect(described_class.issue_id_from_text("https://other.com/issue/TDOT-1")).to be_nil
    end
  end

  describe ".resolve_for_topic" do
    it "reads cached value on topic" do
      topic.custom_fields[DiscourseYoutrack::IssueIdResolver::TOPIC_CF] = "TDOT-100"
      topic.save_custom_fields
      expect(described_class.resolve_for_topic(topic)).to eq("TDOT-100")
    end

    it "reads cache via TopicCustomField when list PreloadedProxy blocks access" do
      topic.custom_fields[DiscourseYoutrack::IssueIdResolver::TOPIC_CF] = "TDOT-100"
      topic.save_custom_fields
      Topic.preload_custom_fields([topic], ["unrelated_field"])

      expect(described_class.resolve_for_topic(topic)).to eq("TDOT-100")
    end

    it "parses first post and caches on topic" do
      first_post.update_column(
        :cooked,
        '<a href="https://youtrack.example.com/issue/TDOT-437">',
      )
      id = described_class.resolve_for_topic(topic.reload)
      expect(id).to eq("TDOT-437")
      expect(topic.reload.custom_fields[DiscourseYoutrack::IssueIdResolver::TOPIC_CF]).to eq(
        "TDOT-437",
      )
    end
  end
end
