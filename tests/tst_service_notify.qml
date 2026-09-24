import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// A message landing in the mirror pops its notification right away instead of
// waiting for the 12-second tick, and a burst folds into one helper pass.
TestCase {
  id: testCase
  name: "ServiceNotify"

  Component { id: serviceComponent; Oma.Service {} }

  function createService() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.railReady = true
    service.notificationsEnabled = true
    var process = findChild(service, "notifyProcess")
    tryVerify(function() { return process.running }, 2000, "the startup tick runs once")
    process.running = false
    process.exited(0)
    return service
  }

  function test_a_store_change_notifies_without_waiting_for_the_tick() {
    var service = createService()
    var process = findChild(service, "notifyProcess")
    verify(!process.running)
    service.refreshFromStore()
    service.refreshFromStore()
    service.refreshFromStore()
    verify(!process.running, "a burst waits for the debounce")
    tryVerify(function() { return process.running }, 3000)
  }

  function test_a_change_during_a_pass_runs_one_more_pass() {
    var service = createService()
    var process = findChild(service, "notifyProcess")
    service.runNotify()
    verify(process.running)
    service.runNotify()
    verify(service.notifyPending)
    process.running = false
    process.exited(0)
    tryVerify(function() { return process.running }, 3000, "the pending pass runs")
    verify(!service.notifyPending)
  }

  function test_nothing_runs_with_notifications_off() {
    var service = createService()
    var process = findChild(service, "notifyProcess")
    service.notificationsEnabled = false
    service.refreshFromStore()
    wait(1300)
    verify(!process.running)
  }
}
