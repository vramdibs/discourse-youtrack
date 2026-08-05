# frozen_string_literal: true

RSpec.describe DiscourseYoutrack::PingbackMarker do
  before { enable_current_plugin }

  it "appends query param to url" do
    expect(described_class.append_to_url("https://example.com/t/1/2", 99)).to eq(
      "https://example.com/t/1/2?discourse_youtrack_pingback=99",
    )
  end

  it "detects html comment and query marker" do
    expect(described_class.present_in?("<!-- discourse-youtrack-pingback:42 -->")).to eq(true)
    expect(
      described_class.present_in?("https://x/t/1/2?discourse_youtrack_pingback=42"),
    ).to eq(true)
    expect(described_class.present_in?("ordinary youtrack update")).to eq(false)
  end

  it "extracts post id" do
    expect(described_class.post_id_from("<!-- discourse-youtrack-pingback:77 -->")).to eq(77)
  end
end
