import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui as Ui
import "MediaModel.js" as MediaModel
import "TimeFormat.js" as TimeFormat
import "LinkModel.js" as LinkModel

// One WhatsApp-style timeline item: quote, content, interactive options,
// reactions, delivery metadata, and the hover action surface stay together so
// the virtualized conversation remains cheap at any window width.
Item {
  id: root

  required property var message
  required property color foreground
  required property color background
  required property color accent
  required property color dim
  required property color dimmer
  required property string fontFamily
  property bool groupChat: false
  property bool selected: false
  property bool narrow: false
  property bool busyMedia: false
  property bool surfaceActive: true
  property string activePlaybackId: ""
  property real audioRate: 1
  signal audioRateRequested(real rate)
  property string timeFormat: "auto"

  signal selectedRequested()
  signal openMediaRequested(string path)
  signal downloadMediaRequested()
  signal replyRequested()
  signal reactionRequested(string emoji)
  signal editRequested()
  signal deleteRequested(bool forMe)
  signal forwardRequested()
  signal copyRequested(string text)
  signal saveRequested()

  // Sent from here, not yet stored by the mirror: shown at once, with no
  // actions that need a WhatsApp message id.
  readonly property bool pending: message && message.pending === true
  // While its actions or menus are showing, the row must draw above its
  // neighbours: lists stack delegates in creation order, not by position.
  readonly property bool raised: actionSurface.visible || reactionPicker.opened
    || actionMenu.opened
  // The message menu, as data: tests and the right-click path share it.
  readonly property var menuActions: pending
    ? [{ label: "Copy text", action: "copy", show: true }]
    : [
    { label: "Reply", action: "reply", show: true },
    { label: "React", action: "react", show: true },
    { label: "Copy text", action: "copy", show: root.bodyText !== "" },
    { label: "Copy link", action: "copy-link", show: root.links.length > 0 },
    { label: "Edit", action: "edit", show: root.message.from_me && !root.message.media_type },
    { label: "Save as…", action: "save", show: root.hasMedia },
    { label: "Forward", action: "forward", show: true },
    { label: "Delete for me", action: "delete-me", show: true },
    { label: "Delete for everyone", action: "delete-all", show: root.message.from_me }
  ].filter(function(item) { return item.show })
  function runMenuAction(action) {
    actionMenu.close()
    if (action === "reply") root.replyRequested()
    else if (action === "react") reactionPicker.open()
    else if (action === "copy") root.copyRequested(root.bodyText)
    else if (action === "copy-link") root.copyRequested(root.links[0].url)
    else if (action === "edit") root.editRequested()
    else if (action === "forward") root.forwardRequested()
    else if (action === "save") root.saveRequested()
    else root.deleteRequested(action === "delete-me")
  }
  signal optionRequested(int index)
  signal playbackRequested(string messageId)

  readonly property string bodyText: {
    if (!message || message["text"] === undefined || message["text"] === null) return ""
    return String(message["text"])
  }
  readonly property var links: LinkModel.extract(bodyText, 3)
  readonly property string fullTimestampText: Qt.formatDateTime(
    new Date(Number(message.timestamp || 0) * 1000),
    Qt.locale().dateFormat(Locale.LongFormat) + " · "
      + TimeFormat.clockPattern(timeFormat, Qt.locale().timeFormat(Locale.ShortFormat)))
  readonly property string timestampText: Qt.formatDateTime(
    new Date(Number(message.timestamp || 0) * 1000),
    TimeFormat.clockPattern(timeFormat, Qt.locale().timeFormat(Locale.ShortFormat)))
  readonly property real maximumWidth: width * (narrow ? 0.92 : 0.76)
  readonly property real metadataWidth: timestampMetrics.advanceWidth
    + (message.edited === true ? editedMetrics.advanceWidth + Style.space(6) : 0)
    + (message.starred === true ? Style.space(16) : 0)
  readonly property real naturalTextWidth: Math.max(
    messageMetrics.advanceWidth,
    senderMetrics.advanceWidth,
    metadataWidth)
  readonly property bool hasMedia: String(message.media_type || "") !== ""
  readonly property real mediaWidth: Math.min(maximumWidth,
    MediaModel.isVisual(message) ? 560 : 520)
  readonly property real desiredWidth: message.media_type
      || String(message.quoted_id || "") !== ""
      || (Array.isArray(message.buttons) && message.buttons.length > 0)
    ? (hasMedia ? mediaWidth : maximumWidth)
    : Math.max(Style.space(88), Math.min(maximumWidth,
        naturalTextWidth + Style.space(22)))
  readonly property var reactionPills: {
    var grouped = ({})
    var values = Array.isArray(message.reactions) ? message.reactions : []
    for (var i = 0; i < values.length; i++) {
      var emoji = String(values[i].emoji || "")
      if (emoji === "") continue
      if (!grouped[emoji]) grouped[emoji] = { emoji: emoji, count: 0, mine: false }
      grouped[emoji].count += 1
      grouped[emoji].mine = grouped[emoji].mine || values[i].from_me === true
    }
    return Object.keys(grouped).map(function(key) { return grouped[key] })
  }

  implicitHeight: bubble.height + (reactionRow.visible ? reactionRow.height + Style.space(4) : 0)
  height: implicitHeight

  // The whole row, not only the bubble, reveals the actions: they sit beside
  // the bubble when there is room, and the pointer must be able to reach them.
  HoverHandler { id: rowHover }

  // Right-click opens the same actions at the pointer; the hover "More"
  // button opens them under the action strip.
  property bool menuAtPointer: false
  property point menuPoint: Qt.point(0, 0)
  function openContextMenu(x, y) {
    menuAtPointer = true
    menuPoint = Qt.point(x, y)
    root.selectedRequested()
    actionMenu.open()
  }

  TextMetrics {
    id: messageMetrics
    text: root.bodyText
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
  }

  TextMetrics {
    id: senderMetrics
    text: !root.message.from_me && root.groupChat
      ? String(root.message.sender || "") : ""
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  TextMetrics {
    id: timestampMetrics
    text: root.timestampText
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  TextMetrics {
    id: editedMetrics
    text: "edited"
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.italic: true
  }

  Rectangle {
    id: bubble
    objectName: "messageBubbleSurface"
    opacity: root.pending ? 0.72 : 1
    anchors.right: root.message.from_me ? parent.right : undefined
    anchors.left: root.message.from_me ? undefined : parent.left
    width: root.desiredWidth
    height: bubbleColumn.implicitHeight + Style.space(18)
    radius: Style.cornerRadius
    color: root.message.from_me
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
      : Style.normalFillFor(root.foreground, root.accent)
    border.width: root.selected ? 1 : 0
    border.color: root.accent


    Column {
      id: bubbleColumn
      objectName: "messageBubbleContent"
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: Style.space(9)
      spacing: Style.space(6)

      Text {
        textFormat: Text.PlainText
        visible: root.message.forwarded === true
        text: "󰜎  Forwarded"
        color: root.dimmer
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.italic: true
      }

      Text {
        textFormat: Text.PlainText
        visible: !root.message.from_me && root.groupChat
        text: String(root.message.sender || "")
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        visible: String(root.message.quoted_id || "") !== ""
        width: parent.width
        height: quoteColumn.implicitHeight + Style.space(12)
        radius: Style.cornerRadius
        color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0.52)

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Style.space(3)
          radius: width / 2
          color: root.accent
        }

        Column {
          id: quoteColumn
          anchors.left: parent.left
          anchors.leftMargin: Style.space(10)
          anchors.right: parent.right
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            textFormat: Text.PlainText
            text: String(root.message.quoted_sender || "WhatsApp")
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
          Text {
            textFormat: Text.PlainText
            id: quoteText
            width: parent.width
            text: String(root.message.quoted_text || "") !== ""
              ? String(root.message.quoted_text)
              : "[" + String(root.message.quoted_media_type || "message") + "]"
            color: root.dim
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      MediaBubble {
        visible: !!root.message.media_type
        width: parent.width
        message: root.message
        foreground: root.foreground
        background: root.background
        accent: root.accent
        dim: root.dim
        dimmer: root.dimmer
        fontFamily: root.fontFamily
        busy: root.busyMedia
        surfaceActive: root.surfaceActive
        activePlaybackId: root.activePlaybackId
        audioRate: root.audioRate
        onAudioRateRequested: function(rate) { root.audioRateRequested(rate) }
        onPlaybackRequested: function(messageId) {
          root.playbackRequested(messageId)
        }
        onOpenRequested: function(path) { root.openMediaRequested(path) }
        onDownloadRequested: root.downloadMediaRequested()
      }

      TextEdit {
        id: messageText
        visible: root.bodyText.length > 0
        width: parent.width
        height: contentHeight
        text: root.bodyText
        color: root.foreground
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        readOnly: true
        selectByMouse: true
        persistentSelection: true
        selectionColor: root.accent
        selectedTextColor: root.background
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        onSelectedTextChanged: {
          if (selectedText !== "") selectionCopyDelay.restart()
        }

        Timer {
          id: selectionCopyDelay
          interval: 140
          repeat: false
          onTriggered: {
            var value = String(messageText.selectedText || "")
            if (value !== "") root.copyRequested(value)
          }
        }
      }

      // Links open from chips under the text: the body stays plain text, so
      // no markup is ever rendered from a message.
      Flow {
        objectName: "messageLinks"
        visible: root.links.length > 0
        width: parent.width
        spacing: Style.space(6)
        Repeater {
          model: root.links
          delegate: Rectangle {
            required property var modelData
            objectName: "messageLink"
            width: Math.min(linkLabel.implicitWidth + Style.space(30), parent ? parent.width : 400)
            height: Style.space(26)
            radius: Style.cornerRadius
            color: linkHover.hovered ? Style.hoverFillFor(root.foreground, root.accent)
              : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
            Text {
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.leftMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: "󰌹"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Text {
              textFormat: Text.PlainText
              id: linkLabel
              anchors.left: parent.left
              anchors.leftMargin: Style.space(24)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              elide: Text.ElideMiddle
              text: modelData.label
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
            Ui.PanelToolTip { visible: linkHover.hovered; text: "Open " + modelData.url }
            TapHandler { onTapped: Qt.openUrlExternally(modelData.url) }
          }
        }
      }

      Column {
        visible: Array.isArray(root.message.buttons) && root.message.buttons.length > 0
        width: parent.width
        spacing: Style.space(4)
        Repeater {
          model: Array.isArray(root.message.buttons) ? root.message.buttons : []
          delegate: Rectangle {
            required property var modelData
            required property int index
            width: parent.width
            height: Style.space(34)
            radius: Style.cornerRadius
            color: optionHover.hovered
              ? Style.hoverFillFor(root.foreground, root.accent)
              : Qt.rgba(root.background.r, root.background.g, root.background.b, 0.45)
            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              width: parent.width - Style.space(16)
              text: String(modelData.display_text || "Option " + (index + 1))
              color: root.accent
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            HoverHandler { id: optionHover }
            TapHandler { onTapped: root.optionRequested(index + 1) }
          }
        }
      }

      Row {
        anchors.right: parent.right
        spacing: Style.space(6)
        Text {
          textFormat: Text.PlainText
          visible: root.message.edited === true
          text: "edited"
          color: root.dimmer
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.italic: true
        }
        Text {
          textFormat: Text.PlainText
          visible: root.message.starred === true
          text: "󰓎"
          color: root.dimmer
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        // No delivery tick: wacli's mirror records no delivery or read
        // receipts, so any tick here would be a claim the data cannot back.
        // A pending message shows a clock until the stored row replaces it.
        Text {
          textFormat: Text.PlainText
          objectName: "messagePending"
          visible: root.pending
          text: "󰅐"
          color: root.dimmer
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          HoverHandler { id: pendingHover }
          Ui.PanelToolTip {
            visible: pendingHover.hovered
            text: root.message.send_state === "sent"
              ? "Sent · saving it on this computer" : "Sending…"
          }
        }
        Text {
          textFormat: Text.PlainText
          objectName: "messageTimestamp"
          text: root.timestampText
          color: root.dimmer
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          HoverHandler { id: timestampHover }
          Ui.PanelToolTip { visible: timestampHover.hovered; text: root.fullTimestampText }
        }
      }
    }

    Rectangle {
      id: actionSurface
      objectName: "messageActions"
      z: 5
      // Beside the bubble (incoming: right, outgoing: left) whenever the row
      // has room, in the dropdown too, so the actions never cover the text.
      // A bubble as wide as the row gets them straddling its top edge, where
      // they cover only the padding.
      readonly property bool outside: root.width - bubble.width >= width + Style.space(16)
      visible: !root.pending && (rowHover.hovered || reactionPicker.opened || actionMenu.opened)
      // Positioned explicitly: conditional anchors keep the previous edge when
      // `outside` flips, which pinned both sides to the bubble's right edge.
      x: outside
        ? (root.message.from_me ? -width - Style.space(6) : parent.width + Style.space(6))
        : (root.message.from_me ? Style.space(5) : parent.width - width - Style.space(5))
      y: outside ? 0 : -Math.round(height / 2)
      width: actionRow.implicitWidth + Style.space(6)
      height: actionRow.implicitHeight + Style.space(4)
      radius: height / 2
      // Opaque: the theme's normal fill is about 4% alpha, so inside the
      // bubble (the dropdown's layout) the message text showed through and
      // the buttons looked buried under it.
      color: Qt.tint(root.background, Qt.rgba(root.foreground.r, root.foreground.g,
        root.foreground.b, 0.12))
      border.width: 1
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)

      Row {
        id: actionRow
        anchors.centerIn: parent
        spacing: Style.space(1)
        Repeater {
          model: [
            { icon: "󰑚", action: "reply", hint: "Reply" },
            { icon: "󰇵", action: "react", hint: "React" },
            { icon: "󰇙", action: "more", hint: "More actions" }
          ]
          delegate: Ui.PanelActionButton {
            required property var modelData
            objectName: "messageAction-" + modelData.action
            iconText: modelData.icon
            tooltipText: modelData.hint
            foreground: root.dim
            hoverColor: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            size: Style.space(24)
            onClicked: {
              root.selectedRequested()
              if (modelData.action === "reply") root.replyRequested()
              else if (modelData.action === "react") reactionPicker.open()
              else { root.menuAtPointer = false; actionMenu.open() }
            }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      z: -1
      onClicked: root.selectedRequested()
    }

    TapHandler {
      acceptedButtons: Qt.RightButton
      onTapped: function(eventPoint) {
        root.openContextMenu(eventPoint.position.x, eventPoint.position.y)
      }
    }

    Popup {
      id: reactionPicker
      x: Math.max(0, Math.min(bubble.width - width, actionSurface.x))
      y: actionSurface.y + actionSurface.height + Style.space(3)
      width: emojiRow.implicitWidth + Style.space(12)
      height: Style.space(38)
      padding: 0
      closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
      background: Rectangle {
        radius: height / 2
        color: root.background
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
      }
      contentItem: Row {
        id: emojiRow
        anchors.centerIn: parent
        spacing: Style.space(3)
        Repeater {
          model: ["👍", "❤️", "😂", "😮", "😢", "🙏"]
          delegate: Rectangle {
            required property string modelData
            width: Style.space(30)
            height: width
            radius: width / 2
            color: emojiHover.hovered
              ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: modelData
              font.pixelSize: Style.font.body
            }
            HoverHandler { id: emojiHover }
            TapHandler {
              onTapped: {
                reactionPicker.close()
                root.reactionRequested(modelData)
              }
            }
          }
        }
      }
    }

    Popup {
      id: actionMenu
      objectName: "messageActionMenu"
      x: root.menuAtPointer
        ? Math.max(-bubble.x, Math.min(root.width - bubble.x - width, root.menuPoint.x))
        : Math.max(0, bubble.width - width)
      y: root.menuAtPointer
        ? root.menuPoint.y
        : actionSurface.y + actionSurface.height + Style.space(3)
      width: Style.space(178)
      height: menuColumn.implicitHeight + Style.space(10)
      padding: Style.space(5)
      closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
      background: Rectangle {
        radius: Style.cornerRadius
        color: root.background
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
      }
      contentItem: Column {
        id: menuColumn
        spacing: Style.space(2)
        Repeater {
          model: root.menuActions
          delegate: Rectangle {
            required property var modelData
            objectName: "messageMenu-" + modelData.action
            visible: modelData.show
            width: parent.width
            height: visible ? Style.space(32) : 0
            radius: Style.cornerRadius
            color: menuHover.hovered
              ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
            Text {
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.leftMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.label
              color: modelData.action.indexOf("delete") === 0 ? Color.urgent : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            HoverHandler { id: menuHover }
            TapHandler { onTapped: root.runMenuAction(modelData.action) }
          }
        }
      }
    }
  }

  Row {
    id: reactionRow
    visible: root.reactionPills.length > 0
    anchors.top: bubble.bottom
    anchors.topMargin: -Style.space(3)
    anchors.right: root.message.from_me ? bubble.right : undefined
    anchors.left: root.message.from_me ? undefined : bubble.left
    height: visible ? Style.space(24) : 0
    spacing: Style.space(4)

    Repeater {
      model: root.reactionPills
      delegate: Rectangle {
        required property var modelData
        width: reactionText.implicitWidth + Style.space(10)
        height: Style.space(24)
        radius: height / 2
        color: modelData.mine
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
          : root.background
        border.width: 1
        border.color: modelData.mine ? root.accent
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
        Text {
          textFormat: Text.PlainText
          id: reactionText
          anchors.centerIn: parent
          text: modelData.emoji + (modelData.count > 1 ? " " + modelData.count : "")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        TapHandler { onTapped: root.reactionRequested(modelData.mine ? "" : modelData.emoji) }
      }
    }
  }
}
