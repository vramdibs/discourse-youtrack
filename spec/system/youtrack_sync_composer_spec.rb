# frozen_string_literal: true

RSpec.describe "YouTrack sync composer", type: :system, js: true do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
  fab!(:first_post) do
    Fabricate(
      :post,
      topic: topic,
      post_number: 1,
      raw: "https://youtrack.example.com/issue/TDOT-437",
      cooked: '<a href="https://youtrack.example.com/issue/TDOT-437">TDOT-437</a>',
    )
  end

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:composer) { PageObjects::Components::Composer.new }

  before do
    enable_current_plugin
    SiteSetting.discourse_youtrack_enabled = true
    SiteSetting.discourse_youtrack_base_url = "https://youtrack.example.com"
    SiteSetting.discourse_youtrack_api_token = "test-token"
    sign_in(user)
  end

  it "shows the sync checkbox when the topic links to a YouTrack issue" do
    visit("/t/#{topic.id}")
    topic_page.click_reply_button

    expect(composer).to be_opened
    expect(page).to have_css(".discourse-youtrack-sync")
    expect(page).to have_content(I18n.t("js.discourse_youtrack.sync_checkbox"))
    expect(page).to have_content(I18n.t("js.discourse_youtrack.sync_checkbox_help"))
  end

  context "when the topic has no YouTrack link" do
    fab!(:plain_topic) { Fabricate(:topic) }
    fab!(:plain_post) { Fabricate(:post, topic: plain_topic, post_number: 1) }

    it "shows a muted notice in the reply composer" do
      visit("/t/#{plain_topic.id}")
      topic_page.click_reply_button

      expect(composer).to be_opened
      expect(page).to have_css(".discourse-youtrack-sync--muted")
      expect(page).to have_content(I18n.t("js.discourse_youtrack.sync_not_available"))
    end
  end
end
