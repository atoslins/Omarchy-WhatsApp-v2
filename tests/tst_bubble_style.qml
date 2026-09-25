import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma
import "../plugins/omawhatsapp/AccountModel.js" as AccountModel

// The restyle the owner approved (Quiet Terminal): one person's messages form
// a run with tight corners and the name shown once, and the time sits on the
// last line of text when it has room instead of taking a line of its own.
TestCase {
  id: testCase
  name: "BubbleStyle"
  width: 700
  height: 600
  visible: true
  when: windowShown

  Component {
    id: bubbleComponent
    Oma.MessageBubble {
      width: 640
      foreground: "#eeeeee"; background: "#111111"; accent: "#66ccaa"
      dim: "#999999"; dimmer: "#777777"; fontFamily: "monospace"
    }
  }

  function bubble(fields, props) {
    var message = Object.assign({ id: "m1", text: "short", sender: "Sam", sender_jid: "sam@s.whatsapp.net",
      timestamp: 1790280000, from_me: false, media_type: "", reactions: [] }, fields || {})
    return createTemporaryObject(bubbleComponent, testCase, Object.assign({ message: message }, props || {}))
  }

  function test_a_run_is_one_person_within_ten_minutes() {
    var a = { from_me: false, sender_jid: "sam@x", timestamp: 100 }
    verify(AccountModel.sameRun(a, { from_me: false, sender_jid: "sam@x", timestamp: 400 }))
    verify(!AccountModel.sameRun(a, { from_me: false, sender_jid: "ana@x", timestamp: 120 }), "another person")
    verify(!AccountModel.sameRun(a, { from_me: true, timestamp: 120 }), "you in between")
    verify(!AccountModel.sameRun(a, { from_me: false, sender_jid: "sam@x", timestamp: 800 }), "ten minutes later")
    verify(AccountModel.sameRun({ from_me: true, timestamp: 1 }, { from_me: true, timestamp: 50 }))
    verify(!AccountModel.sameRun(null, a))
  }

  function test_joined_bubbles_tighten_the_sender_corner_and_name_once() {
    var first = bubble({}, { groupChat: true })
    var surface = findChild(first, "messageBubbleSurface")
    verify(findChild(first, "messageSender").visible, "the first of a run names the sender")
    compare(surface.bottomLeftRadius, surface.tightCorner, "the tail corner on the sender's side")
    compare(surface.topLeftRadius, surface.roundCorner)
    var next = bubble({}, { groupChat: true, joinsAbove: true })
    verify(!findChild(next, "messageSender").visible, "the name shows once per run")
    compare(findChild(next, "messageBubbleSurface").topLeftRadius, surface.tightCorner)
    var mine = bubble({ from_me: true, sender: "You" }, { joinsAbove: true })
    var mineSurface = findChild(mine, "messageBubbleSurface")
    compare(mineSurface.topRightRadius, mineSurface.tightCorner, "your side is the right one")
    compare(mineSurface.bottomRightRadius, mineSurface.tightCorner)
    compare(mineSurface.topLeftRadius, mineSurface.roundCorner)
  }

  function test_the_time_shares_the_last_line_when_it_fits() {
    var short = bubble({ text: "ok" })
    tryVerify(function() { return short.metaInline }, 1000, "a short text keeps its time on the same line")
    var surface = findChild(short, "messageBubbleSurface")
    var text = findChild(short, "messageText")
    verify(surface.height < text.height + findChild(short, "messageMeta").height + 20,
      "no extra line for the time")
    var wrapped = bubble({ text: "a line that is long enough to fill the whole width of this bubble and wrap at the very end xxxxxxxxxxxxxxxx" })
    wait(50)
    var lastEnd = wrapped.lastLineEnd
    var fits = lastEnd + 10 + findChild(wrapped, "messageMeta").width <= findChild(wrapped, "messageText").width
    compare(wrapped.metaInline, fits, "the time drops below only when the last line is full")
  }

  function test_group_names_get_a_theme_color_each() {
    var one = bubble({})
    var sam = one.senderColor("sam@s.whatsapp.net")
    compare(String(one.senderColor("sam@s.whatsapp.net")), String(sam), "stable per person")
    verify(String(one.senderColor("ana@s.whatsapp.net")) !== String(sam) || String(one.senderColor("bia@s.whatsapp.net")) !== String(sam),
      "different people usually get different colors")
    compare(String(one.senderColor("")), String(one.accent))
  }
}
