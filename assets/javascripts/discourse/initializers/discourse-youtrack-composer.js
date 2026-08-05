import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer("1.8.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.discourse_youtrack_enabled) {
    return;
  }

  api.serializeOnCreate(
    "discourse_youtrack_sync_requested",
    "discourseYoutrackSyncRequested"
  );

  api.modifyClass("model:composer", {
    pluginId: "discourse-youtrack",

    discourseYoutrackSyncRequested: false,

    clearState() {
      this._super(...arguments);
      this.set("discourseYoutrackSyncRequested", false);
    },
  });

  const appEvents = api.container.lookup("service:app-events");

  appEvents.on("composer:opened", () => {
    const composerModel = api.container.lookup("controller:composer").model;
    const topic = composerModel?.topic;

    if (!topic || topic.discourse_youtrack_issue_id) {
      return;
    }

    const topicController = api.container.lookup("controller:topic");
    const issueId = topicController?.model?.discourse_youtrack_issue_id;

    if (issueId) {
      topic.set("discourse_youtrack_issue_id", issueId);
    }
  });

  api.onAppEvent("post:created", (post) => {
    const requested =
      post?.discourse_youtrack_sync_requested === true ||
      post?.discourse_youtrack_sync_requested === "true";

    if (!requested) {
      return;
    }

    const messageBus = api.container.lookup("service:message-bus");
    const flash = api.container.lookup("service:flash");
    const channel = `/discourse-youtrack/post/${post.id}`;

    messageBus.subscribe(channel, (data) => {
      if (data?.status === "error") {
        const key = `discourse_youtrack.sync_error_${data.error}`;
        const fallback = "discourse_youtrack.sync_error_upstream";
        flash.warning(i18n(key, { defaultValue: i18n(fallback) }));
      }
      messageBus.unsubscribe(channel);
    });
  });
});
