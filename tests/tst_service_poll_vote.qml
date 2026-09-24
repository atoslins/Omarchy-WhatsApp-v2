import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// Tapping a poll option votes through the helper's poll-vote command.
TestCase {
  id: testCase
  name: "ServicePollVote"

  Component { id: serviceComponent; Oma.Service {} }

  readonly property var target: ({ account: "work", jid: "team@g.us" })

  function createService() {
    var service = createTemporaryObject(serviceComponent, testCase)
    service.ready = true
    service.statusReady = true
    service.statusAccount = "work"
    service.offlineMode = false
    return service
  }

  function test_a_vote_runs_poll_vote_with_the_exact_options() {
    var service = createService()
    verify(service.votePoll(target, { id: "poll1" }, ["Tuesday"], "app"))
    compare(service.activeWriteKind, "poll-vote")
    var process = findChild(service, "writeProcess")
    compare(process.command[1], "poll-vote")
    var request = JSON.parse(process.payload)
    compare(request.id, "poll1")
    compare(request.options, ["Tuesday"])
    compare(request.jid, "team@g.us")
  }

  function test_a_vote_needs_a_poll_and_a_choice() {
    var service = createService()
    verify(!service.votePoll(target, null, ["Tuesday"], "app"))
    verify(!service.votePoll(target, { id: "poll1" }, [], "app"))
    compare(service.activeWriteKind, "")
  }
}
