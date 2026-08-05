# frozen_string_literal: true

RSpec.describe "YouTrack post create hook" do
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
    Jobs.run_immediately!

    stub_request(:post, "https://youtrack.example.com/api/issues/TDOT-437/comments")
      .to_return(status: 200, body: { id: "yt-comment-99" }.to_json)
  end

  it "syncs a reply when the composer requests YouTrack sync" do
    creator =
      PostCreator.new(
        user,
        topic_id: topic.id,
        raw: "Reply with sync",
        discourse_youtrack_sync_requested: true,
      )
    post = creator.create

    expect(creator.errors).to be_empty
    expect(post.reload.custom_fields[DiscourseYoutrack::SYNC_REQUESTED_CF]).to be_truthy
    expect(post.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to eq("ok")
    expect(post.custom_fields[DiscourseYoutrack::COMMENT_ID_CF]).to eq("yt-comment-99")
  end

  it "does not sync when the composer flag is absent" do
    creator = PostCreator.new(user, topic_id: topic.id, raw: "Reply without sync")
    post = creator.create

    expect(creator.errors).to be_empty
    expect(post.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to be_nil
  end
end
