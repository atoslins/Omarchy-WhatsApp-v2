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
  // Stickers tab: recent stickers of this account; picking one sends it.
  property bool stickersEnabled: false
  property var stickers: []
  property bool stickersLoading: false
  property string tab: "emoji"
  signal stickerPicked(string path)
  signal stickersOpened()
  function showTab(name) {
    tab = name === "stickers" && stickersEnabled ? "stickers" : "emoji"
    if (tab === "stickers") stickersOpened()
    else Qt.callLater(function() { searchField.forceActiveFocus() })
  }
  function chooseSticker(path) {
    var value = String(path || "")
    if (value === "") return false
    stickerPicked(value)
    close()
    return true
  }

  width: Style.space(344)
  height: Style.space(360)
  padding: Style.space(8)
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
  onOpened: {
    query = ""
    searchField.text = ""
    if (tab === "stickers" && stickersEnabled) stickersOpened()
    else { tab = "emoji"; searchField.forceActiveFocus() }
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
    Row {
      id: tabs
      objectName: "pickerTabs"
      visible: root.stickersEnabled
      anchors.top: parent.top
      anchors.left: parent.left
      height: visible ? Style.space(28) : 0
      spacing: Style.space(4)
      Repeater {
        model: [{ id: "emoji", label: "Emoji" }, { id: "stickers", label: "Stickers" }]
        delegate: Rectangle {
          required property var modelData
          objectName: "pickerTab-" + modelData.id
          readonly property bool active: root.tab === modelData.id
          width: tabLabel.implicitWidth + Style.space(20)
          height: Style.space(26)
          radius: height / 2
          color: active ? Style.selectedFillFor(root.foreground, root.accent)
            : (tabHover.hovered ? Style.hoverFillFor(root.foreground, root.accent) : "transparent")
          Text {
            textFormat: Text.PlainText
            id: tabLabel
            anchors.centerIn: parent
            text: modelData.label
            color: parent.active ? root.foreground : root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
          HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.showTab(modelData.id) }
        }
      }
    }
    GridView {
      id: stickerGrid
      objectName: "stickerGrid"
      visible: root.tab === "stickers"
      anchors.top: tabs.bottom
      anchors.topMargin: Style.space(6)
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      clip: true
      cellWidth: Math.floor(width / 4)
      cellHeight: cellWidth
      model: root.stickers
      boundsBehavior: Flickable.StopAtBounds
      delegate: Rectangle {
        required property var modelData
        width: stickerGrid.cellWidth
        height: stickerGrid.cellHeight
        radius: Style.cornerRadius
        color: stickerHover.hovered ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
        AnimatedImage {
          anchors.fill: parent
          anchors.margins: Style.space(4)
          source: "file://" + String(modelData.path || "").split("/").map(function(part) {
            return encodeURIComponent(part) }).join("/")
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          playing: stickerHover.hovered
        }
        HoverHandler { id: stickerHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.chooseSticker(modelData.path) }
      }
    }
    Text {
      textFormat: Text.PlainText
      objectName: "stickerEmpty"
      visible: root.tab === "stickers" && root.stickers.length === 0
      anchors.centerIn: stickerGrid
      width: stickerGrid.width - Style.space(24)
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      text: root.stickersLoading ? "Loading stickers…"
        : "No stickers on this computer yet. Stickers you send or receive show up here."
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    TextField {
      id: searchField
      objectName: "emojiSearch"
      visible: root.tab === "emoji"
      anchors.top: tabs.bottom
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
      visible: root.tab === "emoji"
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
      visible: root.tab === "emoji" && root.shown.length === 0
      anchors.centerIn: grid
      text: "No emoji matches"
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
