import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// The owner found the wait between Send and the message appearing too long:
// a sent text shows at once as a pending bubble, gives way to the stored row
// once the mirror has it, and disappears again if the send fails (the text
// goes back to the composer).
TestCase {
  id: testCase
  name: "PendingSend"
  width: 600
  height: 400
  visible: true
  when: windowShown

  readonly property var target: ({ account: "work", jid: "synthetic@s.whatsapp.net" })

  Component { id: serviceComponent; Oma.Service {} }

  function createService() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.ready = true
    service.statusReady = true
    service.statusAccount = "work"
    service.offlineMode = false
    service.readOnReply = false
    service.selectedChatAccount = "work"
    service.selectedChatJid = target.jid
    service.messages = [{ id: "older", text: "before", from_me: false, timestamp: 10 }]
    return service
  }

  function finish(service, exitCode, payload) {
    var process = findChild(service, "writeProcess")
    process.stdout.text = JSON.stringify(payload)
    process.running = false
    process.exited(exitCode)
  }

  function test_a_sent_text_shows_at_once_and_gives_way_to_the_stored_row() {
    var service = createService()
    verify(service.sendText(target, "  hello there  ", "", [], "app"))
    compare(service.selectedMessages.length, 2)
    var pending = service.selectedMessages[0]
    verify(pending.pending, "newest first: the pending bubble is at the bottom")
    compare(pending.text, "hello there")
    compare(pending.send_state, "sending")
    verify(pending.from_me)
    finish(service, 0, { ok: true, message_id: "SYNTHETIC-SENT" })
    compare(service.selectedMessages[0].send_state, "sent")
    service.messages = [{ id: "SYNTHETIC-SENT", text: "hello there", from_me: true, timestamp: 20 },
                        { id: "older", text: "before", from_me: false, timestamp: 10 }]
    compare(service.selectedMessages.length, 2, "no duplicate once the mirror has it")
    verify(service.selectedMessages[0].pending !== true)
    service.prunePendingSends()
    compare(service.pendingSends.length, 0)
  }

  function test_a_failed_send_removes_the_pending_bubble() {
    var service = createService()
    verify(service.sendText(target, "will fail", "", [], "app"))
    compare(service.selectedMessages.length, 2)
    finish(service, 1, { ok: false, error: "Synthetic failure" })
    compare(service.selectedMessages.length, 1)
    compare(service.pendingSends.length, 0)
  }

  function test_a_pending_bubble_stays_in_its_own_chat() {
    var service = createService()
    verify(service.sendText(target, "for this chat", "", [], "app"))
    service.selectedChatJid = "other@s.whatsapp.net"
    service.messages = []
    compare(service.selectedMessages.length, 0)
    service.selectedChatJid = target.jid
    compare(service.selectedMessages[0].text, "for this chat")
  }

  function test_files_show_a_pending_bubble_until_the_next_refresh() {
    var service = createService()
    verify(service.sendFilesReply(target, ["file:///tmp/synthetic%20report.pdf"], "see this", "", "app"))
    compare(service.selectedMessages[0].text, "📎 synthetic report.pdf\nsee this")
    finish(service, 0, { ok: true })
    compare(service.selectedMessages.length, 2, "still shown until the stored rows arrive")
    service.prunePendingSends()
    compare(service.selectedMessages.length, 1)
  }

  function test_a_picked_sticker_shows_at_once_as_itself() {
    var service = createService()
    verify(service.sendSticker(target, "/tmp/synthetic-sticker.webp", "", "app"))
    var pending = service.selectedMessages[0]
    verify(pending.pending)
    compare(pending.media_type, "sticker")
    compare(pending.local_path, "/tmp/synthetic-sticker.webp", "the bubble shows the sticker, not a label")
    finish(service, 0, { ok: true, kind: "sticker", message_id: "SYNTHETIC-STICKER" })
    compare(service.selectedMessages[0].send_state, "sent")
    service.messages = [{ id: "SYNTHETIC-STICKER", media_type: "sticker", from_me: true, timestamp: 30 }]
    compare(service.selectedMessages.length, 1)
  }

  function test_nothing_is_added_when_the_send_cannot_start() {
    var service = createService()
    service.offlineMode = true
    verify(!service.sendText(target, "offline", "", [], "app"))
    compare(service.pendingSends.length, 0)
  }

  Component {
    id: bubbleComponent
    Oma.MessageBubble {
      width: 420
      message: ({ id: "pending:1", text: "on its way", sender: "You", timestamp: 1787540100,
        from_me: true, media_type: "", reactions: [], pending: true, send_state: "sending" })
      foreground: "#eeeeee"; background: "#111111"; accent: "#66ccaa"
      dim: "#999999"; dimmer: "#777777"; fontFamily: "monospace"
    }
  }

  function test_a_pending_bubble_has_a_clock_and_no_message_actions() {
    var bubble = createTemporaryObject(bubbleComponent, testCase)
    verify(bubble.pending)
    verify(findChild(bubble, "messagePending").visible)
    compare(bubble.menuActions.map(function(item) { return item.action }), ["copy"])
    mouseMove(bubble, bubble.width - 20, 10)
    verify(!findChild(bubble, "messageActions").visible, "reply or react needs a stored message")
    compare(findChild(bubble, "messageBubbleSurface").opacity, 0.72)
  }
}
