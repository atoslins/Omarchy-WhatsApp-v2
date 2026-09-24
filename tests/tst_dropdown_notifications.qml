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
      property bool dropdownConversationVisible: false
      property bool dropdownOpen: false
      function selectChat(chat) {
        selectedChatJid = String(chat.jid)
        selectedChatAccount = String(chat.account || "")
      }
      function discardStages(paths) {}
      function stopVoiceForSurfaceClose() {}
      function refreshMessages() {}
      function refreshChats() {}
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

  function test_only_the_conversation_view_counts_as_on_screen() {
    var service = createTemporaryObject(serviceStub, testCase)
    service.writing = false
    var dropdown = createTemporaryObject(dropdownComponent, testCase,
      { demoMode: false, service: service })
    dropdown.open()
    verify(dropdown.opened)
    compare(dropdown.viewMode, "chats")
    verify(!service.dropdownConversationVisible, "the chat list is not the conversation")
    dropdown.openConversation({ account: "work", jid: "x@s.whatsapp.net", name: "X" })
    compare(dropdown.viewMode, "conversation")
    verify(service.dropdownConversationVisible)
    dropdown.backToChats()
    verify(!service.dropdownConversationVisible)
    dropdown.close()
  }

  function test_footer_names_its_action_and_keeps_keys_in_tooltips() {
    var dropdown = createTemporaryObject(dropdownComponent, testCase)
    compare(findChild(dropdown, "openFullAppLabel").text, "Open full app")
    function texts(item, found) {
      if (typeof item.text === "string") found.push(item.text)
      for (var i = 0; i < item.children.length; i++) texts(item.children[i], found)
      return found
    }
    verify(texts(dropdown, []).every(function(text) { return text.indexOf("J/K  ·") < 0 }),
      "no bare list of keys in the footer")
  }
}
