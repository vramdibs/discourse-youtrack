# frozen_string_literal: true

RSpec.describe Jobs::DeleteYoutrackComment do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
  fab!(:first_post) do
    Fabricate(
      :post,
      topic: topic,
      post_number: 1,
      cooked: '<a href="https://youtrack.example.com/issue/TDOT-38">TDOT-38</a>',
    )
  end

  before do
    enable_current_plugin
    SiteSetting.discourse_youtrack_enabled = true
    SiteSetting.discourse_youtrack_base_url = "https://youtrack.example.com"
    SiteSetting.discourse_youtrack_api_token = "test-token"
  end

  it "deletes the YouTrack comment and clears post fields" do
    stub_request(
      :delete,
      "https://youtrack.example.com/api/issues/TDOT-38/comments/yt-1",
    ).to_return(status: 200, body: "")

    post = Fabricate(:post, topic: topic, post_number: 2, user: user)
    post.custom_fields[DiscourseYoutrack::COMMENT_ID_CF] = "yt-1"
    post.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF] = "ok"
    post.save_custom_fields

    Jobs::DeleteYoutrackComment.new.execute(
      "post_id" => post.id,
      "issue_id" => "TDOT-38",
      "comment_id" => "yt-1",
    )

    expect(post.reload.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to eq("deleted")
    expect(post.custom_fields[DiscourseYoutrack::COMMENT_ID_CF]).to be_nil
  end
end
