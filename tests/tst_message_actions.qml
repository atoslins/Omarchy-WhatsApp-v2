import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

TestCase {
  id: testCase
  name: "MessageActions"
  width: 900
  height: 300
  visible: true
  when: windowShown

  Component {
    id: bubbleComponent
    Oma.MessageBubble {
      width: 900
      message: ({
        id: "synthetic-message",
        text: "Short synthetic text",
        sender: "Demo",
        timestamp: 1787540100,
        from_me: false,
        media_type: "",
        reactions: []
      })
      foreground: "#eeeeee"
      background: "#111111"
      accent: "#66ccaa"
      dim: "#999999"
      dimmer: "#777777"
      fontFamily: "monospace"
    }
  }

  function hoverRow(bubble) {
    mouseMove(bubble, bubble.width / 2, bubble.height / 2)
    wait(50)
  }

  function test_actions_are_hidden_until_the_row_is_hovered() {
    var bubble = createTemporaryObject(bubbleComponent, testCase)
    var actions = findChild(bubble, "messageActions")
    verify(actions !== null)
    mouseMove(testCase, 1, testCase.height - 1)
    wait(50)
    verify(!actions.visible)
    hoverRow(bubble)
    tryVerify(function() { return actions.visible })
  }

  function test_a_row_showing_its_actions_is_raised_over_its_neighbours() {
    // The owner saw the dropdown's hover actions drawn under other messages.
    var bubble = createTemporaryObject(bubbleComponent, testCase)
    verify(!bubble.raised)
    hoverRow(bubble)
    tryVerify(function() { return bubble.raised }, 2000)
    compare(findChild(bubble, "messageActions").z, 5, "the strip sits above the bubble's own content")
  }

  function test_incoming_actions_sit_right_of_the_bubble() {
    var bubble = createTemporaryObject(bubbleComponent, testCase)
    var actions = findChild(bubble, "messageActions")
    var surface = findChild(bubble, "messageBubbleSurface")
    hoverRow(bubble)
    verify(actions.outside)
    verify(actions.x >= surface.width, "actions must not cover the bubble")
  }

  function test_outgoing_actions_sit_left_of_the_bubble() {
    var bubble = createTemporaryObject(bubbleComponent, testCase, {
      message: { id: "mine", text: "Mine", sender: "You", timestamp: 1787540100,
        from_me: true, media_type: "", reactions: [] }
    })
    var actions = findChild(bubble, "messageActions")
    hoverRow(bubble)
    verify(actions.outside)
    verify(actions.x + actions.width <= 0, "actions must sit before the bubble")
  }

  function test_narrow_layout_keeps_actions_inside_the_bubble() {
    var bubble = createTemporaryObject(bubbleComponent, testCase, { narrow: true, width: 340 })
    var actions = findChild(bubble, "messageActions")
    hoverRow(bubble)
    verify(!actions.outside)
    verify(actions.x >= 0)
  }

  function test_actions_move_outside_when_the_layout_widens() {
    var bubble = createTemporaryObject(bubbleComponent, testCase, { narrow: true, width: 340 })
    var actions = findChild(bubble, "messageActions")
    var surface = findChild(bubble, "messageBubbleSurface")
    hoverRow(bubble)
    verify(!actions.outside)
    bubble.narrow = false
    bubble.width = 900
    hoverRow(bubble)
    verify(actions.outside)
    verify(actions.x >= surface.width, "a widened row must not keep the inside anchors")
    verify(actions.x + actions.width <= bubble.width)
  }

  function test_right_click_opens_the_actions_at_the_pointer() {
    var bubble = createTemporaryObject(bubbleComponent, testCase)
    var surface = findChild(bubble, "messageBubbleSurface")
    var menu = findChild(bubble, "messageActionMenu")
    verify(menu !== null)
    verify(!menu.opened)
    mouseClick(surface, 30, 12, Qt.RightButton)
    tryVerify(function() { return menu.opened })
    verify(bubble.menuAtPointer)
    compare(Math.round(menu.y), 12)
  }

  SignalSpy { id: saveSpy; signalName: "saveRequested" }

  function test_save_as_is_offered_for_media_only() {
    var text = createTemporaryObject(bubbleComponent, testCase)
    var actions = function(bubble) { return bubble.menuActions.map(function(item) { return item.action }) }
    verify(actions(text).indexOf("save") < 0, "plain text has nothing to save")
    var media = createTemporaryObject(bubbleComponent, testCase, {
      message: { id: "photo", text: "", sender: "Demo", timestamp: 1787540100,
        from_me: false, media_type: "image", mime_type: "image/png", local_path: "", reactions: [] }
    })
    verify(actions(media).indexOf("save") >= 0)
    compare(media.menuActions.filter(function(item) { return item.action === "save" })[0].label, "Save as…")
    saveSpy.target = media
    saveSpy.clear()
    media.runMenuAction("save")
    compare(saveSpy.count, 1)
  }

  function test_every_action_has_a_recognisable_icon_and_a_tooltip() {
    var bubble = createTemporaryObject(bubbleComponent, testCase)
    var expected = [
      ["reply", "󰑚", "Reply"],
      ["react", "󰇵", "React"],
      ["more", "󰇙", "More actions"]
    ]
    for (var i = 0; i < expected.length; i++) {
      var button = findChild(bubble, "messageAction-" + expected[i][0])
      verify(button !== null, expected[i][0])
      compare(button.iconText, expected[i][1])
      compare(button.tooltipText, expected[i][2])
    }
  }
}
