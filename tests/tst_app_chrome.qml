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
      property var lastChatRead: null
      property bool showAvatars: true
      property bool appConversationVisible: false
      property string railDensity: "comfortable"
      property string syncPauseReason: ""
      property bool chatDetailsWanted: false
      property bool chatDetailsLoading: false
      property var chatDetails: ({})
      function setChatRead(ref, read, owner) {
        lastChatRead = { ref: ref, read: read, owner: owner }
        return true
      }
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

  function test_ctrl_k_jumps_to_a_chat_by_name() {
    var h = createHarness()
    var switcher = findChild(h.app, "quickSwitcher")
    verify(switcher !== null)
    h.app.forceActiveFocus()
    keyClick(Qt.Key_K, Qt.ControlModifier)
    tryCompare(switcher, "opened", true)
    switcher.query = "other"
    compare(switcher.results.length, 1)
    verify(switcher.accept())
    compare(h.service.selectedChatJid, "other@example")
    tryCompare(switcher, "opened", false)
  }

  function test_the_switcher_moves_with_the_arrows_and_finds_archived_chats() {
    var h = createHarness()
    h.service.chats = [workChat, otherChat,
      { account: "work", jid: "old@example", name: "Synthetic archived", kind: "dm", unread: 0, archived: true }]
    var switcher = findChild(h.app, "quickSwitcher")
    h.app.openQuickSwitcher()
    tryCompare(switcher, "opened", true)
    compare(switcher.results.length, 2, "an empty query lists the chats without archived ones")
    switcher.move(1)
    compare(switcher.cursor, 1)
    switcher.move(5)
    compare(switcher.cursor, 1, "the cursor stays inside the list")
    switcher.query = "archived"
    compare(switcher.results.map(function(c) { return c.jid }), ["old@example"])
    compare(switcher.cursor, 0)
    switcher.close()
  }

  function test_rail_views_filter_the_chat_list() {
    var h = createHarness()
    h.service.chats = [
      { account: "work", jid: "shared@example", name: "Synthetic work", kind: "dm", unread: 0 },
      { account: "work", jid: "other@example", name: "Synthetic other", kind: "group", unread: 2 },
      { account: "work", jid: "old@example", name: "Synthetic archived", kind: "dm", unread: 0, archived: true }
    ]
    compare(h.app.visibleChats.length, 2, "archived chats live in their own view")
    verify(findChild(h.app, "railView-archived") !== null)
    var unread = findChild(h.app, "railView-unread")
    tryVerify(function() { return unread.x > 0 && unread.width > 0 }, 2000, "the chips have laid out")
    mouseClick(unread, unread.width / 2, unread.height / 2)
    compare(h.app.chatView, "unread")
    compare(h.app.visibleChats.map(function(c) { return c.jid }), ["other@example"])
    mouseClick(unread, unread.width / 2, unread.height / 2)
    compare(h.app.chatView, "all", "clicking the active view goes back to all")
    h.app.chatView = "archived"
    compare(h.app.visibleChats.map(function(c) { return c.jid }), ["old@example"])
    h.app.chatView = "groups"
    h.service.chats = [workChat]
    verify(findChild(h.app, "railViewEmpty").visible)
  }

  function test_the_header_opens_chat_details_and_escape_closes_them() {
    var h = createHarness()
    h.app.selectChat(workChat)
    var title = findChild(h.app, "conversationTitle")
    verify(title !== null)
    compare(h.service.appConversationVisible, true)
    mouseClick(title, 5, title.height / 2)
    verify(h.app.chatDetailsOpen)
    verify(h.service.chatDetailsWanted, "the service loads the details while the panel is open")
    var panel = findChild(h.app, "chatDetailsPanel")
    verify(panel.visible)
    verify(!h.app.chatDetailsBeside, "a 1000 px window has no room beside the conversation")
    compare(h.service.appConversationVisible, false,
      "a panel covering the conversation does not count as reading it")
    h.app.goBack()
    verify(!h.app.chatDetailsOpen)
    verify(!h.service.chatDetailsWanted)
    compare(h.service.appConversationVisible, true)
  }

  function test_chat_details_open_a_known_person_or_hand_off_to_new_chat() {
    var h = createHarness()
    h.app.chatDetailsOpen = true
    verify(h.app.openFromChatDetails("other@example", "Synthetic other", ""))
    compare(h.service.selectedChatJid, "other@example")
    h.app.chatDetailsOpen = true
    verify(h.app.openFromChatDetails("15550009999@s.whatsapp.net", "Nobody yet", "15550009999"))
    verify(!h.app.chatDetailsOpen)
    tryCompare(findChild(h.app, "newChatDialog"), "opened", true)
  }

  function test_the_rail_line_says_why_this_app_paused_sync() {
    var h = createHarness({ syncActive: false })
    var status = findChild(h.app, "railSyncStatus")
    compare(status.label, "Reconnecting…")
    h.service.syncPauseReason = "sending files"
    compare(status.label, "Sync paused · sending files")
    h.service.syncActive = true
    compare(status.label, "")
  }

  function test_new_chat_is_a_rail_button_with_a_shortcut() {
    var app = createHarness().app
    var button = findChild(app, "railNewChatButton")
    verify(button !== null)
    compare(button.tooltipText, "New chat · Ctrl+N")
    var dialog = findChild(app, "newChatDialog")
    verify(dialog !== null)
    verify(!dialog.opened)
    button.clicked()
    tryCompare(dialog, "opened", true)
    dialog.close()
    tryCompare(dialog, "opened", false)
    app.forceActiveFocus()
    keyClick(Qt.Key_N, Qt.ControlModifier)
    tryCompare(dialog, "opened", true)
  }

  function test_new_chat_opens_an_existing_chat_in_the_rail() {
    var h = createHarness()
    var dialog = findChild(h.app, "newChatDialog")
    h.app.openNewChat()
    tryCompare(dialog, "opened", true)
    dialog.openChatRequested("other@example")
    compare(h.service.selectedChatJid, "other@example")
  }

  function test_a_started_chat_is_selected_once_it_syncs() {
    var h = createHarness()
    var dialog = findChild(h.app, "newChatDialog")
    dialog.chatStarted("15550003333@s.whatsapp.net")
    compare(h.app.pendingOpenChatJid, "15550003333@s.whatsapp.net")
    compare(h.service.selectedChatJid, "shared@example", "not in the rail yet")
    h.service.chats = [workChat, otherChat, {
      account: "work", jid: "15550003333@s.whatsapp.net", name: "Synthetic started",
      kind: "dm", preview: "", unread: 0 }]
    compare(h.service.selectedChatJid, "15550003333@s.whatsapp.net")
    compare(h.app.pendingOpenChatJid, "")
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

  function test_an_open_conversation_offers_no_read_action() {
    var harness = createHarness()
    verify(findChild(harness.app, "conversationReadToggle") === null,
      "the open conversation is read by being open")
    harness.app.toggleChatRead(workChat, false)
    compare(harness.service.lastChatRead.read, false)
    compare(harness.service.lastChatRead.ref.jid, workChat.jid)
  }

  function test_rail_row_offers_the_read_toggle_on_hover() {
    var harness = createHarness()
    var toggle = findChild(harness.app, "chatReadToggle")
    verify(toggle !== null, "every rail row carries the toggle")
    verify(!toggle.visible, "hidden until the row is hovered")
    mouseMove(toggle.parent, toggle.parent.width / 2, toggle.parent.height / 2)
    tryVerify(function() { return toggle.visible })
    toggle.clicked()
    verify(harness.service.lastChatRead !== null)
  }

  function test_right_click_on_a_chat_opens_its_actions() {
    var harness = createHarness()
    var app = harness.app
    var row = findChild(app, "chatReadToggle").parent.parent
    var menu = findChild(app, "chatContextMenu")
    verify(menu !== null)
    mouseMove(row, 40, 20)
    wait(50)
    mouseClick(row, 40, 20, Qt.RightButton)
    tryVerify(function() { return menu.opened })
    compare(app.contextChat.jid, workChat.jid)
    compare(app.contextChatActions.map(function(item) { return item.action }),
      ["unread", "pin", "mute", "archive", "remove-local"])
    verify(app.runChatContextAction("pin"))
    compare(harness.service.lastChatAction.action, "pin")
    compare(harness.service.lastChatAction.ref.jid, workChat.jid)
    verify(!menu.opened)
  }

  function test_chat_menu_read_toggle_targets_that_row() {
    var harness = createHarness()
    var app = harness.app
    app.openChatContextMenu(otherChat, 10, 10)
    verify(app.runChatContextAction("unread"))
    compare(harness.service.lastChatRead.ref.jid, otherChat.jid)
    compare(harness.service.lastChatRead.read, false)
  }

  function test_chat_photos_setting_hides_every_photo() {
    var harness = createHarness()
    var photo = Object.assign({}, workChat, { avatar_path: "__demo_avatar__" })
    harness.service.chats = [photo, otherChat]
    var header = findChild(harness.app, "conversationAvatar")
    tryVerify(function() { return header.avatarReady }, 5000)
    harness.service.showAvatars = false
    verify(!header.showPhoto)
    verify(!header.avatarReady, "no photo loads with the setting off")
  }

  function test_compact_density_shortens_rail_rows() {
    var harness = createHarness()
    var row = findChild(harness.app, "chatReadToggle").parent.parent
    var comfortable = row.height
    harness.service.railDensity = "compact"
    verify(row.height < comfortable)
  }

  function test_save_as_opens_a_save_dialog_with_a_suggested_name() {
    var harness = createHarness()
    var app = harness.app
    verify(app.saveMediaAs({ id: "photo", filename: "trip.jpg", media_type: "image" }))
    var process = findChild(app, "savePickerProcess")
    verify(process.running)
    verify(process.command.indexOf("--save") >= 0)
    verify(process.command.indexOf("--confirm-overwrite") >= 0)
    verify(process.command.filter(function(arg) {
      return arg.indexOf("--filename=") === 0 && arg.endsWith("/Downloads/trip.jpg") }).length === 1)
  }

  function test_app_reports_when_the_conversation_is_on_screen() {
    var harness = createHarness()
    verify(harness.service.appConversationVisible, "open app showing the selected chat")
    harness.app.settingsOpen = true
    verify(!harness.service.appConversationVisible, "settings cover the conversation")
    harness.app.settingsOpen = false
    harness.app.opened = false
    verify(!harness.service.appConversationVisible, "a closed app shows nothing")
  }

  function test_list_shows_pinned_muted_and_unsent_drafts() {
    var harness = createHarness()
    var flagged = Object.assign({}, otherChat, { pinned: true, muted: true })
    harness.service.chats = [workChat, flagged]
    var app = harness.app
    verify(app.draftFor(flagged) === "")
    app.composerStates = { "work\nother@example": { text: "see you\nsoon", attachments: [] } }
    compare(app.draftFor(flagged), "see you soon", "one line, drafts of other chats only")
    compare(app.draftFor(workChat), "", "the open chat shows its draft in the composer")
    wait(0)
    var pinned = []
    var muted = []
    function walk(item) {
      if (item.objectName === "chatPinnedIcon" && item.visible) pinned.push(item)
      if (item.objectName === "chatMutedIcon" && item.visible) muted.push(item)
      for (var i = 0; i < item.children.length; i++) walk(item.children[i])
    }
    walk(app)
    compare(pinned.length, 1)
    compare(muted.length, 1)
  }

  function test_desktop_notifications_live_in_settings() {
    var harness = createHarness({ notificationsEnabled: true, notificationsPreview: true })
    var app = harness.app
    app.settingsOpen = true
    findChild(app, "settingsView").openSection("notifications")
    wait(0)
    var notify = findChild(app, "setting-notify")
    var preview = findChild(app, "setting-notify_preview")
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
