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
