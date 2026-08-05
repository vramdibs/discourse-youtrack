# frozen_string_literal: true

RSpec.describe TopicViewSerializer do
  fab!(:user)
  fab!(:topic)
  fab!(:first_post) do
    Fabricate(
      :post,
      topic: topic,
      post_number: 1,
      cooked: '<a href="https://youtrack.example.com/issue/TDOT-437">TDOT-437</a>',
    )
  end

  before do
    enable_current_plugin
    SiteSetting.discourse_youtrack_enabled = true
    SiteSetting.discourse_youtrack_base_url = "https://youtrack.example.com"
    SiteSetting.discourse_youtrack_api_token = "test-token"
  end

  it "includes issue id on topic view serializer" do
    topic_view = TopicView.new(topic.id, user)
    json =
      TopicViewSerializer.new(topic_view, scope: Guardian.new(user), root: false).as_json

    expect(json[:discourse_youtrack_issue_id]).to eq("TDOT-437")
  end
end

RSpec.describe TopicListItemSerializer do
  fab!(:user)
  fab!(:topic)
  fab!(:first_post) do
    Fabricate(
      :post,
      topic: topic,
      post_number: 1,
      cooked: '<a href="https://youtrack.example.com/issue/TDOT-437">TDOT-437</a>',
    )
  end

  before do
    enable_current_plugin
    SiteSetting.discourse_youtrack_enabled = true
    SiteSetting.discourse_youtrack_base_url = "https://youtrack.example.com"
    SiteSetting.discourse_youtrack_api_token = "test-token"
  end

  it "includes cached issue id on topic list item serializer" do
    topic.custom_fields[DiscourseYoutrack::IssueIdResolver::TOPIC_CF] = "TDOT-437"
    topic.save_custom_fields
    Topic.preload_custom_fields(
      [topic],
      [DiscourseYoutrack::IssueIdResolver::TOPIC_CF],
    )

    json =
      TopicListItemSerializer.new(topic, scope: Guardian.new(user), root: false).as_json

    expect(json[:discourse_youtrack_issue_id]).to eq("TDOT-437")
  end

  it "does not raise NotPreloadedError on topic list item without cache" do
    Topic.preload_custom_fields(
      [topic],
      [DiscourseYoutrack::IssueIdResolver::TOPIC_CF],
    )

    expect {
      TopicListItemSerializer.new(topic, scope: Guardian.new(user), root: false).as_json
    }.not_to raise_error
  end
end
