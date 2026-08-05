# frozen_string_literal: true

RSpec.describe Jobs::SyncPostToYoutrack do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
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

  def execute_job(post)
    Jobs::SyncPostToYoutrack.new.execute("post_id" => post.id)
  end

  describe "#execute" do
    it "posts a comment and marks the post as synced" do
      stub_request(:post, "https://youtrack.example.com/api/issues/TDOT-437/comments")
        .to_return(status: 200, body: { id: "yt-comment-1" }.to_json)

      post =
        Fabricate(
          :post,
          topic: topic,
          post_number: 2,
          user: user,
          raw: "Pingback body",
        )
      post.custom_fields[DiscourseYoutrack::SYNC_REQUESTED_CF] = true
      post.save_custom_fields

      execute_job(post)

      expect(post.reload.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to eq("ok")
      expect(post.custom_fields[DiscourseYoutrack::COMMENT_ID_CF]).to eq("yt-comment-1")
      expect(post.custom_fields[DiscourseYoutrack::SYNC_ERROR_CF]).to be_nil
    end

    it "skips the first post even when sync was requested" do
      post = first_post
      post.custom_fields[DiscourseYoutrack::SYNC_REQUESTED_CF] = true
      post.save_custom_fields

      execute_job(post)

      expect(post.reload.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to be_nil
    end

    it "marks auth errors on the post" do
      stub_request(:post, "https://youtrack.example.com/api/issues/TDOT-437/comments")
        .to_return(status: 403, body: "forbidden")

      post =
        Fabricate(:post, topic: topic, post_number: 2, user: user, raw: "Pingback body")
      post.custom_fields[DiscourseYoutrack::SYNC_REQUESTED_CF] = true
      post.save_custom_fields

      execute_job(post)

      expect(post.reload.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to eq("error")
      expect(post.custom_fields[DiscourseYoutrack::SYNC_ERROR_CF]).to eq("auth_failed")
    end

    it "does nothing when sync was not requested" do
      post = Fabricate(:post, topic: topic, post_number: 2, user: user)

      execute_job(post)

      expect(post.reload.custom_fields[DiscourseYoutrack::SYNC_STATUS_CF]).to be_nil
    end
  end
end
