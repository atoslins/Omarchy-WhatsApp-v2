import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma
import "../plugins/omawhatsapp/AccountModel.js" as AccountModel

// The window chrome follows Omarchy's own apps (Omawrite, Omacalc): no title
// bar, controls as small icon buttons with tooltips, status only when it says
// something the user can act on.
TestCase {
  id: testCase
  name: "AppChrome"
  width: 1000
  height: 700
  visible: true
  when: windowShown

  readonly property var workChat: ({
    account: "work", jid: "shared@example", name: "Synthetic work",
    kind: "dm", preview: "", unread: 0
  })
  readonly property var otherChat: ({
    account: "work", jid: "other@example", name: "Synthetic other",
    kind: "dm", preview: "", unread: 0
  })

  Component {
    id: serviceComponent
    Item {
      readonly property alias playback: playbackCoordinator
      property bool appOpen: false
      property bool writing: false
      property bool controlWriting: false
      property bool settingsWriting: false
      property bool statusReady: true
      property bool railReady: true
      property bool offlineMode: false
      property bool syncActive: true
      property bool notificationsEnabled: true
      property bool notificationsPreview: false
      property bool notifyAvailable: true
      property bool sendReadReceipts: false
      property bool showUnreadCount: true
      property bool multiAccount: true
      property int dropdownRows: 7
      property int composerMaxLines: 6
      property string timeFormat: "auto"
      property string statusAccount: "work"
      property string selectedChatAccount: "work"
      property string selectedChatJid: "shared@example"
      property string selectedChatName: "Synthetic work"
      property string selectedChatKind: "dm"
      property string activeWriteAccount: ""
      property string activeWriteChatJid: ""
      property string activeWriteKind: ""
      property string voiceDraftAccount: ""
      property string voiceDraftJid: ""
      property string voiceState: "idle"
      property int voiceDurationMs: 0
      property int voicePlaybackPosition: 0
      property bool voicePlaying: false
      property bool loadingMembers: false
      property bool loadingMessages: false
      property string mediaDownloadId: ""
      property string errorText: ""
      property var chats: []
      property var accounts: []
      property var messages: []
      property var members: []
      property var accountOperations: ({
        linkBusy: false, avatarBusy: false, statusMessage: ""
      })
      property var lastPreference: null
      property var lastDelete: null
      property var lastForward: null
      property var lastPoll: null
      property var lastChatAction: null
      property var discarded: []

      Oma.PlaybackCoordinator { id: playbackCoordinator }

      signal textPasted(string text, var chatRef, string owner)
      signal attachmentPasted(string path, var chatRef, string owner)
      signal writeCompleted(string kind, var chatRef, var request, string owner)
      signal writeFailed(string message, var chatRef, var details, string owner)
      signal controlCompleted(string kind)
      signal controlFailed(string message)
      signal settingsCompleted()
      signal settingsFailed(string message)

      function selectChat(chat) {
        selectedChatAccount = String(chat.account || "")
        selectedChatJid = String(chat.jid || "")
        selectedChatName = String(chat.name || "")
        selectedChatKind = String(chat.kind || "")
        statusAccount = selectedChatAccount
      }
      function deleteMessage(ref, item, forMe, owner) {
        lastDelete = { ref: ref, item: item, forMe: forMe, owner: owner }
        return true
      }
      function forwardMessage(ref, item, targetJid, owner) {
        lastForward = { ref: ref, item: item, targetJid: targetJid, owner: owner }
        return true
      }
      function sendPoll(ref, question, options, selectable, owner) {
        lastPoll = {
          ref: ref, question: question, options: options,
          selectable: selectable, owner: owner
        }
        return true
      }
      function discardStages(paths) { discarded = paths.slice() }
      function discardStage(path) { discarded = [path] }
      function refresh() {}
      function refreshChats() {}
      function refreshMessages() {}
      function dismissNotifications(jid, account) {}
      function stopVoiceRecording() {}
      function stopVoiceForSurfaceClose() {}
      function toggleVoice() { return false }
      function toggleVoicePlayback() {}
      function discardVoice() {}
      function sendVoiceDraft() { return false }
      function pasteClipboard() { return false }
      function sendFilesReply() { return false }
      function sendSticker() { return false }
      function sendText() { return false }
      function editMessage() { return false }
      function search() {}
      function closeApp() {}
      function selectItem() {}
      function chatAction(ref, action, owner) {
        lastChatAction = { ref: ref, action: action, owner: owner }
        return true
      }
      function downloadMedia() { return false }
      function reactTo() { return false }
      function selectOption() { return false }
      property var lastNotifications: null
      function setNotifications(enabled, preview) {
        lastNotifications = { enabled: enabled, preview: preview }
        return true
      }
      property var lastOnline: null
      function setOnline(online) { lastOnline = online; return true }
      function setPreference(key, value) {
        lastPreference = { key: key, value: value }
        return true
      }
    }
  }

  Component {
    id: appComponent
    Oma.App { width: 1000; height: 700 }
  }

  function createHarness(overrides) {
    var service = createTemporaryObject(serviceComponent, testCase)
    verify(service !== null)
    service.chats = [workChat, otherChat]
    for (var key in (overrides || {})) service[key] = overrides[key]
    service.selectChat(workChat)
    var app = createTemporaryObject(appComponent, testCase, { service: service })
    verify(app !== null)
    app.opened = true
    return { app: app, service: service }
  }

  function test_there_is_no_title_bar_above_the_chat_list() {
    var app = createHarness().app
    var settings = findChild(app, "railSettingsButton")
    verify(settings !== null)
    verify(settings.mapToItem(app, 0, 0).y < 40,
      "the rail must start at the top of the window")
  }

  function test_rail_controls_are_icon_buttons_with_tooltips() {
    var app = createHarness().app
    var settings = findChild(app, "railSettingsButton")
    var collapse = findChild(app, "railCollapseButton")
    compare(settings.tooltipText, "Settings")
    compare(collapse.tooltipText, "Hide chat list · Ctrl+B")
    verify(collapse.visible)
    settings.clicked()
    verify(app.settingsOpen)
  }

  function test_hidden_chat_list_offers_the_way_back_in_the_conversation() {
    var app = createHarness().app
    var show = findChild(app, "showChatListButton")
    verify(show !== null)
    verify(!show.visible, "no toggle in the conversation while the list is visible")
    findChild(app, "railCollapseButton").clicked()
    verify(app.sidebarCollapsed)
    verify(show.visible)
    compare(show.tooltipText, "Show chat list · Ctrl+B")
    show.clicked()
    verify(!app.sidebarCollapsed)
  }

  function test_conversation_subtitle_is_empty_for_a_single_account() {
    var app = createHarness({ multiAccount: false }).app
    var subtitle = findChild(app, "conversationSubtitle")
    verify(subtitle !== null)
    compare(subtitle.text, "")
    verify(!subtitle.visible)
  }

  function test_conversation_subtitle_names_the_account_when_several_are_linked() {
    var app = createHarness({ multiAccount: true }).app
    compare(findChild(app, "conversationSubtitle").text, AccountModel.labelOf(workChat))
  }

  function test_sync_status_only_appears_when_not_connected() {
    var harness = createHarness()
    var status = findChild(harness.app, "railSyncStatus")
    verify(status !== null)
    verify(!status.visible, "connected sync needs no status line")
    harness.service.syncActive = false
    compare(status.label, "Reconnecting…")
    verify(status.visible)
    harness.service.offlineMode = true
    compare(status.label, "Offline · local archive")
    harness.service.statusReady = false
    compare(status.label, "Loading…")
  }

  function test_ctrl_number_chat_jumps_are_gone() {
    var app = createHarness().app
    verify(typeof app.selectChatAt === "undefined")
  }

  function test_desktop_notifications_live_in_settings() {
    var harness = createHarness({ notificationsEnabled: true, notificationsPreview: true })
    var app = harness.app
    app.settingsOpen = true
    var notify = findChild(app, "notifySwitch")
    var preview = findChild(app, "notifyPreviewSwitch")
    verify(notify !== null && preview !== null)
    verify(notify.checked)
    verify(preview.checked)
    notify.toggled()
    compare(harness.service.lastNotifications.enabled, false)
    compare(harness.service.lastNotifications.preview, null)
    preview.toggled()
    compare(harness.service.lastNotifications.enabled, null)
    compare(harness.service.lastNotifications.preview, false)
  }
}
