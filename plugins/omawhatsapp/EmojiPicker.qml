import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "EmojiModel.js" as EmojiModel

// Emoji picker for both composers. It reads Omarchy's own emoji list and
// inserts at the field's cursor, so the clipboard is never touched and the
// choice lands in the exact draft it was opened from.
Popup {
  id: root
  objectName: "emojiPicker"

  property var target: null
  property color foreground: Color.foreground
  // Named surface, because Popup already owns `background`.
  property color surface: Color.background
  property color accent: Color.accent
  // Popup already owns `dim` too.
  property color muted: foreground
  property string fontFamily: Style.font.family
  property var emojis: []
  property string query: ""
  property var recent: []
  readonly property string dataPath: String(Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy")
    + "/shell/plugins/emojis/emojis.json"
  readonly property var results: EmojiModel.filter(emojis, query, 400)
  readonly property var shown: query === "" && recent.length > 0
    ? recent.map(function(emoji) { return { e: emoji, k: "recent" } }).concat(results)
    : results
  signal picked(string emoji)

  width: Style.space(344)
  height: Style.space(360)
  padding: Style.space(8)
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
  onOpened: {
    query = ""
    searchField.text = ""
    searchField.forceActiveFocus()
  }

  function choose(emoji) {
    var value = String(emoji || "")
    if (value === "") return false
    if (target && typeof target.insert === "function") {
      var position = Number(target.cursorPosition || 0)
      target.insert(position, value)
      target.cursorPosition = position + value.length
    }
    recent = EmojiModel.remember(recent, value, 16)
    picked(value)
    close()
    if (target && typeof target.forceActiveFocus === "function") target.forceActiveFocus()
    return true
  }

  FileView {
    path: root.dataPath
    onLoaded: root.emojis = EmojiModel.parse(text())
  }

  background: Rectangle {
    radius: Style.cornerRadius
    color: root.surface
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
  }

  contentItem: Item {
    TextField {
      id: searchField
      objectName: "emojiSearch"
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      placeholderText: "Search emoji"
      foreground: root.foreground
      accent: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      onTextChanged: root.query = text
      Keys.onReturnPressed: if (root.shown.length > 0) root.choose(root.shown[0].e)
      Keys.onEnterPressed: if (root.shown.length > 0) root.choose(root.shown[0].e)
    }
    GridView {
      id: grid
      objectName: "emojiGrid"
      anchors.top: searchField.bottom
      anchors.topMargin: Style.space(6)
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      clip: true
      cellWidth: Math.floor(width / 8)
      cellHeight: cellWidth
      model: root.shown
      boundsBehavior: Flickable.StopAtBounds
      delegate: Rectangle {
        required property var modelData
        width: grid.cellWidth
        height: grid.cellHeight
        radius: Style.cornerRadius
        color: emojiHover.hovered ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
        Text {
          textFormat: Text.PlainText
          anchors.centerIn: parent
          text: modelData.e
          font.pixelSize: Style.font.icon
        }
        HoverHandler { id: emojiHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.choose(modelData.e) }
      }
    }
    Text {
      textFormat: Text.PlainText
      visible: root.shown.length === 0
      anchors.centerIn: grid
      text: "No emoji matches"
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
