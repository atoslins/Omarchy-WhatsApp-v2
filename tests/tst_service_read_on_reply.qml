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
}
