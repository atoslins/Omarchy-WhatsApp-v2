import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// L235: the first run explains what OmaWhatsApp is and links the phone from
// the window, instead of an empty list that says "Loading…".
TestCase {
  id: testCase
  name: "Onboarding"
  width: 1100
  height: 760
  visible: true
  when: windowShown

  Component {
    id: operationsStub
    QtObject {
      property bool linkBusy: false
      property bool avatarBusy: false
      property string statusMessage: ""
      property string linked: ""
      function linkMainAccount(name) { linked = name; linkBusy = true
        statusMessage = "Scan the QR code in the terminal with your phone"; return true }
    }
  }
  Component {
    id: serviceStub
    QtObject {
      property bool wacliInstalled: true
      property bool anyAuthenticated: false
      property string defaultAccountName: "primary"
      property var accountOperations: null
    }
  }
  Component { id: viewComponent; Oma.OnboardingView { width: 900; height: 700 } }
  Component { id: appComponent; Oma.App { width: 1100; height: 760; demoMode: true; opened: true } }

  function test_the_welcome_links_the_main_account_from_the_window() {
    var service = createTemporaryObject(serviceStub, testCase)
    service.accountOperations = createTemporaryObject(operationsStub, testCase)
    var view = createTemporaryObject(viewComponent, testCase, { service: service })
    compare(findChild(view, "onboardingTitle").text, "Link your WhatsApp")
    verify(findChild(view, "onboardingSteps").visible)
    verify(!findChild(view, "onboardingWacliMissing").visible)
    verify(view.startLink())
    compare(service.accountOperations.linked, "primary", "the main account, by its own name")
    verify(view.linking)
    verify(findChild(view, "onboardingStatus").text.indexOf("QR code") > 0)
  }

  function test_without_wacli_it_says_what_to_install() {
    var service = createTemporaryObject(serviceStub, testCase)
    service.wacliInstalled = false
    var view = createTemporaryObject(viewComponent, testCase, { service: service })
    verify(findChild(view, "onboardingWacliMissing").visible)
    verify(!findChild(view, "onboardingSteps").visible)
    compare(findChild(view, "onboardingTitle").text, "One more piece first")
  }

  function test_the_app_shows_it_until_something_is_linked() {
    var app = createTemporaryObject(appComponent, testCase)
    var view = findChild(app, "onboardingView")
    verify(!view.visible, "a linked account goes straight to the chats")
    app.open(JSON.stringify({ demo: true, onboarding: true }))
    verify(view.visible)
  }
}
