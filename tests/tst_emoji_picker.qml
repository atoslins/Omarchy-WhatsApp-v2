import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma
import "../plugins/omawhatsapp/EmojiModel.js" as EmojiModel

TestCase {
  id: testCase
  name: "EmojiPicker"
  width: 900
  height: 700
  visible: true
  when: windowShown

  Component { id: editComponent; TextEdit { width: 200; height: 40 } }
  Component { id: pickerComponent; Oma.EmojiPicker {} }
  Component { id: appComponent; Oma.App { width: 900; height: 700; demoMode: true } }
  Component { id: dropdownComponent; Oma.Dropdown { demoMode: true; viewMode: "conversation" } }

  function test_model_parses_filters_and_falls_back() {
    var data = EmojiModel.parse('[{"e":"😀","k":"grinning smile"},{"e":"🔥","k":"fire hot"}]')
    compare(data.length, 2)
    compare(EmojiModel.filter(data, "fire", 10).map(function(item) { return item.e }), ["🔥"])
    verify(EmojiModel.parse("not json").length >= 10, "a broken file still leaves a usable list")
    compare(EmojiModel.remember(["a", "b"], "b", 16), ["b", "a"])
  }

  function test_choosing_inserts_at_the_cursor_and_remembers_it() {
    var edit = createTemporaryObject(editComponent, testCase, { text: "hi there" })
    var picker = createTemporaryObject(pickerComponent, testCase, { target: edit })
    edit.cursorPosition = 2
    picker.open()
    verify(picker.choose("🔥"))
    compare(edit.text, "hi🔥 there")
    compare(edit.cursorPosition, 2 + "🔥".length)
    verify(!picker.opened)
    compare(picker.recent[0], "🔥")
  }

  function test_app_composer_has_the_emoji_button() {
    var app = createTemporaryObject(appComponent, testCase)
    app.opened = true
    var button = findChild(app, "composerEmojiButton")
    var input = findChild(app, "composerInput")
    verify(button !== null)
    compare(button.tooltipText, "Emoji")
    var picker = findChild(button, "emojiPicker")
    verify(picker !== null)
    compare(picker.target, input)
    button.clicked()
    tryVerify(function() { return picker.opened })
    input.text = ""
    picker.choose("👍")
    compare(input.text, "👍")
  }

  function test_dropdown_swaps_paste_for_emoji() {
    var dropdown = createTemporaryObject(dropdownComponent, testCase)
    dropdown.currentChat = dropdown.demoChats[0]
    verify(findChild(dropdown, "composerPasteButton") === null)
    var button = findChild(dropdown, "composerEmojiButton")
    verify(button !== null)
    var picker = findChild(button, "emojiPicker")
    compare(picker.target, findChild(dropdown, "composerInput"))
  }
}
