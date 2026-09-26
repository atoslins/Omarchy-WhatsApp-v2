import QtQuick
import qs.Commons
import qs.Ui

// First run: nothing linked yet. What WhatsApp for Omarchy is, what stays on this
// computer, and the three steps to link the phone, with the button that
// opens the QR code. With no wacli, what to install first.
Rectangle {
  id: root

  property var service: null
  property bool demoMode: false
  property color foreground: Color.foreground
  property color background: Color.background
  property color accent: Color.accent
  property color dim: foreground
  property string fontFamily: Style.font.family
  readonly property var operations: service ? service.accountOperations : null
  readonly property bool wacliMissing: !demoMode && !!service && service.wacliInstalled === false
  readonly property bool linking: !!operations && operations.linkBusy === true

  function startLink() {
    if (demoMode || !service || !operations) return false
    return operations.linkMainAccount(service.defaultAccountName)
  }

  color: background
  MouseArea { anchors.fill: parent }

  Flickable {
    anchors.fill: parent
    contentHeight: Math.max(height, welcomeColumn.implicitHeight + Style.space(64))
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: welcomeColumn
      width: Math.min(Style.space(560), parent.width - Style.space(48))
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(Style.space(32), (parent.height - implicitHeight) / 2)
      spacing: Style.space(20)

      Row {
        spacing: Style.space(14)
        Rectangle {
          width: Style.space(52)
          height: width
          radius: width / 2
          color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
          Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: "󰖣"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.space(28)
          }
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(3)
          Text {
            textFormat: Text.PlainText
            objectName: "onboardingTitle"
            text: root.wacliMissing ? "One more piece first" : "Link your WhatsApp"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading + 4
            font.weight: Font.Bold
          }
          Text {
            textFormat: Text.PlainText
            text: "WhatsApp on your Omarchy desktop, kept on this computer."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      // No wacli: nothing can link yet.
      Rectangle {
        objectName: "onboardingWacliMissing"
        visible: root.wacliMissing
        width: parent.width
        height: missingColumn.implicitHeight + Style.space(28)
        radius: Style.cornerRadius + 4
        color: Style.normalFillFor(root.foreground, root.accent)
        Column {
          id: missingColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: Style.space(16)
          spacing: Style.space(8)
          Text {
            textFormat: Text.PlainText
            width: parent.width
            wrapMode: Text.Wrap
            text: "WhatsApp for Omarchy talks to WhatsApp through wacli, which is not installed yet."
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
          Text {
            textFormat: Text.PlainText
            width: parent.width
            wrapMode: Text.Wrap
            text: "Install wacli at ~/.local/bin/wacli, then open WhatsApp for Omarchy again: this screen continues from there."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      // The three steps, and the button that shows the QR code.
      Rectangle {
        objectName: "onboardingSteps"
        visible: !root.wacliMissing
        width: parent.width
        height: stepsColumn.implicitHeight + Style.space(32)
        radius: Style.cornerRadius + 4
        color: Style.normalFillFor(root.foreground, root.accent)
        Column {
          id: stepsColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: Style.space(18)
          spacing: Style.space(14)
          Repeater {
            model: [
              "On your phone, open WhatsApp → Settings → Linked devices → Link a device.",
              "Click Show QR code: a terminal opens with the code.",
              "Scan it with the phone. This window fills in by itself; the first sync can take a few minutes."
            ]
            delegate: Row {
              required property var modelData
              required property int index
              width: stepsColumn.width
              spacing: Style.space(12)
              Rectangle {
                width: Style.space(24)
                height: width
                radius: width / 2
                color: root.accent
                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: String(index + 1)
                  color: root.background
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.weight: Font.Bold
                }
              }
              Text {
                textFormat: Text.PlainText
                width: parent.width - Style.space(36)
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.Wrap
                text: modelData
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
          Row {
            spacing: Style.space(14)
            Rectangle {
              id: linkButton
              objectName: "onboardingLink"
              width: linkButtonLabel.implicitWidth + Style.space(36)
              height: Style.space(40)
              radius: Style.cornerRadius + 2
              opacity: root.linking ? 0.6 : 1
              color: linkHover.hovered && !root.linking ? Qt.lighter(root.accent, 1.1) : root.accent
              Text {
                textFormat: Text.PlainText
                id: linkButtonLabel
                anchors.centerIn: parent
                text: root.linking ? "Waiting for your phone…" : "Show QR code"
                color: root.background
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.weight: Font.Bold
              }
              HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
              TapHandler { enabled: !root.linking; onTapped: root.startLink() }
            }
            Text {
              textFormat: Text.PlainText
              objectName: "onboardingStatus"
              anchors.verticalCenter: parent.verticalCenter
              visible: text !== ""
              text: root.operations ? String(root.operations.statusMessage || "") : ""
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }

      // What stays here, before anyone links anything.
      Column {
        width: parent.width
        spacing: Style.space(8)
        Text {
          textFormat: Text.PlainText
          text: "WHAT STAYS ON THIS COMPUTER"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption - 1
          font.letterSpacing: 1.4
        }
        Repeater {
          model: [
            "Your chats and media are kept in a local copy, readable even offline.",
            "Messages go only to WhatsApp itself: there is no WhatsApp for Omarchy server or account.",
            "It is a linked device, like WhatsApp Web: your phone stays the main one."
          ]
          delegate: Row {
            required property var modelData
            width: parent.width
            spacing: Style.space(10)
            Text {
              textFormat: Text.PlainText
              text: "󰄬"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              textFormat: Text.PlainText
              width: parent.width - Style.space(24)
              wrapMode: Text.Wrap
              text: modelData
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }
      }
    }
  }
}
