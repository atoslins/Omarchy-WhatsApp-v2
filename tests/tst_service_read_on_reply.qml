import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// Replying shows you read the chat, so the unread count clears the way the
// phone clears it. wacli's mark-read only syncs your own devices.
TestCase {
  id: testCase
  name: "ServiceReadOnReply"

  Component { id: serviceComponent; Oma.Service {} }

  readonly property var target: ({ account: "work", jid: "synthetic@s.whatsapp.net" })

  function createService(unread) {
    var service = createTemporaryObject(serviceComponent, testCase)
    verify(service !== null)
    service.ready = true
    service.statusReady = true
    service.statusAccount = "work"
    service.offlineMode = false
    service.chats = [{
      account: "work", jid: target.jid, name: "Synthetic", kind: "dm",
      unread: unread, notification_unread: unread, preview: "", timestamp: 1
    }]
    return service
  }

  function test_every_content_send_counts_as_a_reply() {
    var service = createService(0)
    for (var kind of ["send", "files", "voice", "sticker", "poll"])
      verify(service.replyKinds.indexOf(kind) >= 0, kind)
    for (var other of ["react", "edit", "delete", "forward", "chat-action"])
      verify(service.replyKinds.indexOf(other) < 0, other)
  }

  function test_reply_clears_the_count_and_marks_the_exact_chat_read() {
    var service = createService(3)
    verify(service.markReadAfterReply(target))
    compare(service.chats[0].unread, 0)
    compare(service.chats[0].notification_unread, 0)
    tryCompare(service, "activeWriteKind", "chat-action")
    compare(service.activeWriteChatJid, target.jid)
    compare(service.activeWriteAccount, "work")
  }

  function test_nothing_happens_without_unread_messages() {
    var service = createService(0)
    verify(!service.markReadAfterReply(target))
    wait(300)
    compare(service.activeWriteKind, "")
  }

  function test_the_preference_turns_it_off() {
    var service = createService(2)
    service.readOnReply = false
    verify(!service.markReadAfterReply(target))
    compare(service.chats[0].unread, 2)
  }

  function test_offline_mode_is_respected() {
    var service = createService(2)
    service.offlineMode = true
    verify(!service.markReadAfterReply(target))
    compare(service.chats[0].unread, 2)
  }

  function test_a_write_in_flight_delays_the_mark_read() {
    var service = createService(4)
    service.writing = true
    verify(service.markReadAfterReply(target))
    wait(400)
    compare(service.activeWriteKind, "", "must wait for the running write")
    service.writing = false
    tryCompare(service, "activeWriteKind", "chat-action")
  }

  function openService(unread) {
    var service = createService(unread)
    service.selectedChatAccount = "work"
    service.selectedChatJid = target.jid
    service.sendReadReceipts = true
    // The service's own hidden App instance owns appConversationVisible, so
    // these tests put the conversation on screen through the dropdown flag.
    service.dropdownOpen = true
    service.dropdownConversationVisible = true
    service.syncActive = true
    return service
  }

  function test_open_chat_waits_while_sync_is_paused() {
    var service = openService(2)
    service.syncActive = false
    verify(!service.readOpenChatIfUnread(service.chats[0]),
      "a paused sync holds the store lock; reading would block the write queue")
    wait(200)
    compare(service.activeWriteKind, "")
    service.syncActive = true
    service.lastAutoReadKey = ""
    verify(service.readOpenChatIfUnread(service.chats[0]))
  }

  function test_new_messages_in_the_open_chat_are_read() {
    var service = openService(2)
    verify(service.readOpenChatIfUnread(service.chats[0]))
    tryCompare(service, "activeWriteKind", "chat-action")
    compare(service.activeWriteChatJid, target.jid)
  }

  function test_a_closed_window_reads_nothing() {
    var service = openService(2)
    service.dropdownConversationVisible = false
    service.dropdownOpen = false
    verify(!service.readOpenChatIfUnread(service.chats[0]))
    wait(200)
    compare(service.activeWriteKind, "")
  }

  function test_only_the_chat_on_screen_is_read() {
    var service = openService(2)
    service.selectedChatJid = "someone-else@s.whatsapp.net"
    verify(!service.readOpenChatIfUnread(service.chats[0]))
  }

  function test_mark_as_unread_holds_while_the_chat_stays_open() {
    var service = openService(0)
    verify(service.setChatRead(target, false, "app"))
    compare(service.manualUnreadKey, "work\n" + target.jid)
    service.writing = false
    var unreadChat = Object.assign({}, service.chats[0], { unread: 1 })
    verify(!service.readOpenChatIfUnread(unreadChat),
      "an explicit unread is not undone by the next refresh")
    service.selectChat(unreadChat)
    compare(service.manualUnreadKey, "", "choosing the chat again reads it")
  }

  function test_repeated_refreshes_do_not_loop_a_failing_read() {
    var service = openService(2)
    verify(service.readOpenChatIfUnread(service.chats[0]))
    verify(!service.readOpenChatIfUnread(service.chats[0]),
      "a second refresh within the throttle window does nothing")
  }

  function test_photo_refresh_runs_by_itself_only_with_every_window_closed() {
    var service = createService(0)
    compare(service.autoRefreshAvatars, false, "off by default: a batch pauses sync and loses events")
    service.autoRefreshAvatars = true
    service.autoAvatarNotBefore = 0
    service.appOpen = true
    verify(!service.maybeAutoRefreshAvatars(), "an open window is never interrupted")
    service.appOpen = false
    service.autoRefreshAvatars = false
    verify(!service.maybeAutoRefreshAvatars(), "the setting turns it off")
    service.autoRefreshAvatars = true
    service.offlineMode = true
    verify(!service.maybeAutoRefreshAvatars(), "offline never reaches WhatsApp")
    service.offlineMode = false
    verify(service.maybeAutoRefreshAvatars())
    verify(service.accountOperations.avatarBusy)
    verify(!service.maybeAutoRefreshAvatars(), "one batch at a time")
  }

  function test_photo_refresh_backs_off_once_nothing_more_is_due() {
    var service = createService(0)
    var before = Date.now()
    service.accountOperations.avatarRefreshFinished(3, 0)
    verify(service.autoAvatarNotBefore - before >= service.autoAvatarQuietGap - 1000)
    service.accountOperations.avatarRefreshFinished(5, 40)
    verify(service.autoAvatarNotBefore - Date.now() <= service.autoAvatarBusyGap + 1000,
      "photos still due bring the next batch soon")
  }

  function test_save_media_goes_to_the_helper_for_the_exact_chat() {
    var service = createService(0)
    service.offlineMode = true
    verify(service.saveMedia(target, { id: "photo" }, "/tmp/out.png", "app"),
      "saving a copy is allowed offline; the helper refuses only a download")
    compare(service.activeWriteKind, "save-media")
    compare(service.activeWriteChatJid, target.jid)
  }

  function test_dropdown_showing_only_the_list_reads_nothing() {
    // The owner's report: a new message arrived, the bar dropdown was open on
    // its chat list, and the last selected chat was marked read anyway.
    var service = openService(2)
    service.dropdownOpen = true
    service.dropdownConversationVisible = false
    verify(!service.readOpenChatIfUnread(service.chats[0]),
      "the list is on screen, not the conversation")
    wait(200)
    compare(service.activeWriteKind, "")
    service.dropdownConversationVisible = true
    verify(service.readOpenChatIfUnread(service.chats[0]))
  }
}
