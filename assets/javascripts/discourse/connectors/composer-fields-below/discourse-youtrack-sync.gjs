import Component from "@glimmer/component";
import { getOwner } from "@ember/application";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";

export default class DiscourseYoutrackSync extends Component {
  static shouldRender(args, context) {
    return (
      context.siteSettings?.discourse_youtrack_enabled &&
      args.model?.action !== "createTopic"
    );
  }

  get model() {
    return this.args.outletArgs.model;
  }

  get issueId() {
    this.ensureIssueIdOnTopic();
    return this.model?.topic?.discourse_youtrack_issue_id;
  }

  get isReply() {
    return this.model?.action === "reply";
  }

  ensureIssueIdOnTopic() {
    const topic = this.model?.topic;

    if (!topic || topic.discourse_youtrack_issue_id) {
      return;
    }

    const topicController = getOwner(this).lookup("controller:topic");
    const issueId = topicController?.model?.discourse_youtrack_issue_id;

    if (issueId) {
      topic.set("discourse_youtrack_issue_id", issueId);
    }
  }

  @action
  onToggle(event) {
    this.model.set("discourseYoutrackSyncRequested", event.target.checked);
  }

  <template>
    {{#if this.issueId}}
      <div class="control-group full-width discourse-youtrack-sync">
        <label class="checkbox-label">
          <input
            type="checkbox"
            checked={{this.model.discourseYoutrackSyncRequested}}
            {{on "change" this.onToggle}}
          />
          {{i18n "discourse_youtrack.sync_checkbox"}}
        </label>
        <div class="instructions">
          {{i18n "discourse_youtrack.sync_checkbox_help"}}
        </div>
      </div>
    {{else if this.isReply}}
      <div
        class="control-group full-width discourse-youtrack-sync discourse-youtrack-sync--muted"
      >
        <span>{{i18n "discourse_youtrack.sync_not_available"}}</span>
      </div>
    {{/if}}
  </template>
}
