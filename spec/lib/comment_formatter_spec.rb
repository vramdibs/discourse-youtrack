# frozen_string_literal: true

require "rails_helper"

describe DiscourseYoutrack::CommentFormatter do
  fab!(:user) { Fabricate(:user, name: "Test User", username: "testuser") }
  fab!(:post) { Fabricate(:post, user: user, raw: "Проверка pingback") }

  before { enable_current_plugin }

  it "formats comment with header, body, link marker, and html marker" do
    text = described_class.format(post)
    expect(text).to include("Test User в Discourse:")
    expect(text).to include("Проверка pingback")
    expect(text).to include("[ответ в Discourse]")
    expect(text).to include("discourse_youtrack_pingback=#{post.id}")
    expect(text).to include("<!-- discourse-youtrack-pingback:#{post.id} -->")
  end

  it "falls back to username when name is blank" do
    user.update_column(:name, nil)
    post.reload
    expect(described_class.format(post)).to include("testuser в Discourse:")
  end
end
