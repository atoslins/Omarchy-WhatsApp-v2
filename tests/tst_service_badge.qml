import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// The bar badge counts unread chats, not messages: the owner found a message
// total confusing, and WhatsApp's own icon counts conversations.
TestCase {
  id: testCase
  name: "ServiceBadge"

  Component { id: serviceComponent; Oma.Service {} }

  function test_a_pause_this_app_caused_names_its_reason() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.syncActive = true
    service.writing = true
    service.activeWriteKind = "files"
    compare(service.syncPauseReason, "", "sync is up: nothing to explain")
    service.syncActive = false
    compare(service.syncPauseReason, "sending files")
    service.activeWriteKind = "send"
    compare(service.syncPauseReason, "", "a delegated send never pauses sync; this is a real outage")
    service.writing = false
    service.numberCheck = { loading: true }
    compare(service.syncPauseReason, "checking a number")
  }

  function test_the_badge_counts_chats_and_the_tooltip_names_both() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.railReady = true
    service.offlineMode = false
    service.chats = [
      { account: "work", jid: "a@s.whatsapp.net", notification_unread: 5 },
      { account: "work", jid: "b@s.whatsapp.net", notification_unread: 2 },
      { account: "work", jid: "c@s.whatsapp.net", notification_unread: 0 }
    ]
    compare(service.notificationUnreadCount, 2)
    compare(service.notificationMessageCount, 7)
    compare(service.barTooltip,
      "OmaWhatsApp · 2 unread chats · 7 messages · middle-click to dismiss")
    service.chats = [{ account: "work", jid: "a@s.whatsapp.net", notification_unread: 1 }]
    compare(service.barTooltip,
      "OmaWhatsApp · 1 unread chat · 1 message · middle-click to dismiss")
    service.chats = []
    compare(service.notificationUnreadCount, 0)
    compare(service.barTooltip, "OmaWhatsApp · no unread chats")
  }

  function test_an_identical_rail_answer_keeps_the_current_model() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.ready = true
    service.statusReady = true
    service.statusAccount = "work"
    service.offlineMode = false
    var process = findChild(service, "chatsProcess")
    verify(process !== null)
    var answer = JSON.stringify({ ok: true, chats: [
      { account: "work", jid: "a@s.whatsapp.net", name: "Synthetic", kind: "dm", unread: 1, notification_unread: 1 }] })
    process.stdout.text = answer
    process.running = false
    process.exited(0)
    var first = service.chats
    compare(first.length, 1)
    process.stdout.text = answer
    process.exited(0)
    verify(service.chats === first, "the same answer does not replace the model")
    service.setChatRead({ account: "work", jid: "a@s.whatsapp.net" }, true, "app")
    compare(service.lastChatsRaw, "", "a local change makes the next answer apply")
    process.stdout.text = answer
    process.exited(0)
    compare(service.chats[0].unread, 1, "the mirror's answer wins again")
  }
}
