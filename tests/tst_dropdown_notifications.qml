import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

TestCase {
  id: testCase
  name: "DropdownNotifications"
  width: 700
  height: 800
  visible: true
  when: windowShown

  Component {
    id: serviceStub
    Item {
      property bool writing: true
      property string activeWriteOwner: "service"
      property var chats: []
      property var messages: []
      property var accounts: []
      property string selectedChatJid: ""
      property string selectedChatAccount: ""
      function selectChat(chat) { selectedChatJid = String(chat.jid) }
      function discardStages(paths) {}
      function stopVoiceForSurfaceClose() {}
      function refreshMessages() {}
    }
  }

  Component {
    id: dropdownComponent
    Oma.Dropdown { demoMode: true }
  }

  function test_toggle_opens_closes_and_reopens() {
    // No service is attached: this never reads a private store or sends receipts.
    var dropdown = createTemporaryObject(dropdownComponent, testCase, { demoMode: false })
    verify(dropdown !== null)
    compare(dropdown.opened, false)
    dropdown.toggle()
    compare(dropdown.opened, true)
    dropdown.toggle()
    compare(dropdown.opened, false)
    dropdown.toggle()
    compare(dropdown.opened, true)
    dropdown.close()
  }

  function test_clear_all_requires_confirmation_and_stays_local() {
    var dropdown = createTemporaryObject(dropdownComponent, testCase)
    verify(dropdown !== null)
    compare(dropdown.notificationCount, 4)

    verify(dropdown.requestClearNotifications())
    compare(dropdown.clearConfirmOpen, true)
    var confirmation = findChild(dropdown, "clearNotificationsConfirm")
    verify(confirmation !== null)
    verify(confirmation.handleKey({ key: Qt.Key_Escape }))
    compare(dropdown.clearConfirmOpen, false)
    compare(dropdown.notificationCount, 4)

    verify(dropdown.requestClearNotifications())
    verify(confirmation.handleKey({ key: Qt.Key_Return }))
    compare(dropdown.clearConfirmOpen, false)
    compare(dropdown.notificationCount, 0)
    compare(dropdown.requestClearNotifications(), false)
  }

  function test_the_count_filters_to_unread_chats() {
    var dropdown = createTemporaryObject(dropdownComponent, testCase)
    var all = dropdown.filteredChats.length
    verify(!dropdown.unreadOnly)
    var badge = findChild(dropdown, "notificationBadge")
    verify(badge !== null)
    verify(dropdown.badgeTapped(Qt.LeftButton))
    verify(dropdown.unreadOnly)
    verify(dropdown.filteredChats.length > 0)
    verify(dropdown.filteredChats.length < all)
    verify(dropdown.filteredChats.every(function(chat) { return Number(chat.unread || 0) > 0 }))
    dropdown.badgeTapped(Qt.LeftButton)
    verify(!dropdown.unreadOnly)
    dropdown.badgeTapped(Qt.RightButton)
    verify(dropdown.clearConfirmOpen, "right-click still clears the badge, with confirmation")
  }

  function test_background_writes_neither_show_sending_nor_block_going_back() {
    var service = createTemporaryObject(serviceStub, testCase)
    var dropdown = createTemporaryObject(dropdownComponent, testCase,
      { demoMode: false, service: service })
    verify(!dropdown.sending, "automatic mark-read is not this surface sending")
    dropdown.viewMode = "conversation"
    dropdown.backToChats()
    compare(dropdown.viewMode, "chats")
    service.activeWriteOwner = "dropdown"
    verify(dropdown.sending, "its own send still shows")
  }
}
