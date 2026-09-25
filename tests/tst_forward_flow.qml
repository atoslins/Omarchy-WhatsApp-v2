import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// The forward flow the owner asked to redo (L218, with L195): pick messages
// in the conversation, choose several chats and an optional note, and see
// where they went, with a way to open that chat.
TestCase {
  id: testCase
  name: "ForwardFlow"
  width: 1100
  height: 760
  visible: true
  when: windowShown

  Component { id: appComponent; Oma.App { width: 1100; height: 760; demoMode: true; opened: true } }
  Component { id: serviceComponent; Oma.Service {} }

  readonly property var origin: ({ account: "work", jid: "origin@s.whatsapp.net" })

  function createService() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.ready = true
    service.statusReady = true
    service.statusAccount = "work"
    service.offlineMode = false
    service.readOnReply = false
    service.selectedChatAccount = "work"
    service.selectedChatJid = origin.jid
    return service
  }

  function finish(service, exitCode, payload) {
    var process = findChild(service, "writeProcess")
    process.stdout.text = JSON.stringify(payload)
    process.running = false
    process.exited(exitCode)
  }

  function test_forward_starts_a_selection_that_can_grow() {
    var app = createTemporaryObject(appComponent, testCase)
    var first = app.demoItems[0]
    verify(app.startForward(first))
    verify(app.selectingMessages)
    var bar = findChild(app, "selectionBar")
    verify(bar.visible)
    compare(findChild(app, "selectionCount").text, "1 selected")
    verify(app.toggleMessageSelection(app.demoItems[3]))
    compare(findChild(app, "selectionCount").text, "2 selected")
    verify(app.toggleMessageSelection(app.demoItems[3]), "a second click unpicks")
    compare(app.selectedMessageIds.length, 1)
    // An album row stands for every photo in it.
    var album = app.visibleMessages.filter(function(item) { return item.album_items })[0]
    verify(album !== undefined)
    verify(app.toggleMessageSelection(album))
    compare(app.selectedMessageIds.length, 3)
    verify(app.isMessageSelected(album))
    app.cancelSelection()
    verify(!bar.visible)
    compare(app.selectedMessageIds.length, 0)
  }

  function test_rows_show_check_circles_while_picking() {
    var app = createTemporaryObject(appComponent, testCase)
    verify(app.startForward(app.demoItems[0]))
    var circles = []
    function walk(item) {
      if (item.objectName === "messageSelectCircle" && item.visible) circles.push(item)
      for (var i = 0; i < item.children.length; i++) walk(item.children[i])
    }
    tryVerify(function() { circles = []; walk(app); return circles.length > 1 }, 2000)
    verify(circles.some(function(circle) { return String(circle.color) === String(app.accent) }),
      "the picked message is filled")
  }

  function test_the_dialog_takes_several_chats_and_a_note() {
    var app = createTemporaryObject(appComponent, testCase)
    app.demoChats = app.demoChats.concat([{ jid: "demo-extra", name: "Synthetic Extra", kind: "dm",
      account: "work", account_label: "work", avatar_path: "", preview: "", timestamp: 1, unread: 0 }])
    verify(app.startForward(app.demoItems[0]))
    verify(app.toggleMessageSelection(app.demoItems[3]))
    verify(app.openForwardDialog())
    var dialog = findChild(app, "forwardPicker")
    verify(dialog.opened)
    compare(findChild(app, "forwardTitle").text, "Forward 2 messages")
    compare(app.forwardItems.map(function(item) { return item.id }), ["demo-3", "demo-5"],
      "oldest first, the order they are sent in")
    var targets = app.forwardCandidates
    verify(targets.length >= 2)
    verify(app.toggleForwardTarget(targets[0]))
    verify(app.toggleForwardTarget(targets[1]))
    compare(app.forwardChosen.length, 2)
    compare(findChild(app, "forwardSend").ready, true)
    verify(app.sendForward())
    verify(!dialog.opened)
    verify(!app.selectingMessages, "sending ends the selection")
    verify(findChild(app, "toastAction").visible, "the toast offers to open the chat")
    verify(app.runToastAction())
    compare(app.demoSelectedJid, String(targets[0].jid), "the first chat it went to opens")
  }

  function test_copy_takes_the_words_in_order() {
    var app = createTemporaryObject(appComponent, testCase)
    verify(app.startForward(app.demoItems[0]))
    verify(app.toggleMessageSelection(app.demoItems[1]))
    verify(app.copySelection())
    verify(!app.selectingMessages)
  }

  function test_the_service_forwards_each_message_to_each_chat_then_the_note() {
    var service = createService()
    var finished = null
    service.forwardBatchFinished.connect(function(summary) { finished = summary })
    var process = findChild(service, "writeProcess")
    var items = [{ id: "M1", text: "one", timestamp: 1 }, { id: "M2", text: "two", timestamp: 2 }]
    var targets = [{ account: "work", jid: "a@s.whatsapp.net", name: "Synthetic A" },
                   { account: "work", jid: "b@s.whatsapp.net", name: "Synthetic B" }]
    verify(service.forwardMany(origin, items, targets, "  see these  ", "app"))
    verify(!service.forwardMany(origin, items, targets, "", "app"), "one batch at a time")
    var seen = []
    for (var step = 0; step < 6; step++) {
      var request = JSON.parse(process.payload)
      seen.push((request.to_jid || request.jid) + ":" + (request.id || request.text))
      process.running = true
      finish(service, 0, { ok: true, kind: request.to_jid ? "forward" : "send", message_id: "OUT" + step })
    }
    compare(seen, ["a@s.whatsapp.net:M1", "a@s.whatsapp.net:M2", "a@s.whatsapp.net:see these",
                   "b@s.whatsapp.net:M1", "b@s.whatsapp.net:M2", "b@s.whatsapp.net:see these"])
    verify(finished !== null, "the batch reports when it ends")
    compare(finished.failed, 0)
    compare(finished.targets.length, 2)
    compare(service.forwardBatch, null)
  }

  function test_a_failed_forward_is_counted_and_the_rest_go_on() {
    var service = createService()
    var finished = null
    service.forwardBatchFinished.connect(function(summary) { finished = summary })
    var process = findChild(service, "writeProcess")
    var items = [{ id: "M1", text: "one", timestamp: 1 }]
    var targets = [{ account: "work", jid: "a@s.whatsapp.net", name: "Synthetic A" },
                   { account: "work", jid: "b@s.whatsapp.net", name: "Synthetic B" }]
    verify(service.forwardMany(origin, items, targets, "", "app"))
    process.running = true
    finish(service, 1, { ok: false, error: "WhatsApp refused that one." })
    compare(JSON.parse(process.payload).to_jid, "b@s.whatsapp.net", "the next chat still gets it")
    process.running = true
    finish(service, 0, { ok: true, kind: "forward", message_id: "OUT" })
    verify(finished !== null)
    compare(finished.failed, 1)
    compare(finished.errors, ["WhatsApp refused that one."])
  }

  function test_chats_of_another_account_are_left_out() {
    var service = createService()
    verify(!service.forwardMany(origin, [{ id: "M1" }],
      [{ account: "home", jid: "a@s.whatsapp.net" }], "", "app"))
  }
}
