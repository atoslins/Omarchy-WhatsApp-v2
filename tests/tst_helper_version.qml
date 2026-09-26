import QtQuick
import QtTest
import "../plugins/omawhatsapp" as Oma

// An update that replaced only the plugin leaves an older helper in
// ~/.local/bin: the app says to run the installer instead of a raw error.
TestCase {
  id: testCase
  name: "HelperVersion"

  Component { id: serviceComponent; Oma.Service { manifest: ({ id: "io.github.atoslins.whatsapp", version: "0.15.0" }) } }

  function status(service, payload, stderrText) {
    var process = findChild(service, "statusProcess")
    process.stdout.text = payload === null ? "" : JSON.stringify(payload)
    process.stderr.text = stderrText || ""
    process.running = false
    process.exited(payload === null ? 2 : 0)
  }
  function ok(version) {
    var payload = { ok: true, installed: true, authenticated: true, database_ready: true,
      sync_active: true, any_authenticated: true, account: "", accounts: [] }
    if (version !== undefined) payload.helper_version = version
    return payload
  }

  function test_a_matching_helper_says_nothing() {
    var service = createTemporaryObject(serviceComponent, testCase)
    status(service, ok("0.15.0"))
    verify(!service.helperOutdated)
    verify(service.barTooltip.indexOf("update incomplete") < 0)
  }

  function test_without_a_manifest_nothing_is_compared() {
    var service = createTemporaryObject(serviceComponent, testCase, { manifest: null })
    status(service, ok())
    verify(!service.helperOutdated)
  }

  function test_an_older_helper_asks_for_the_installer() {
    var service = createTemporaryObject(serviceComponent, testCase)
    status(service, ok())
    verify(service.helperOutdated, "a helper without a version predates this app")
    verify(service.helperOutdatedText.indexOf("./scripts/install") >= 0)
    verify(service.barTooltip.indexOf("update incomplete") >= 0)
    status(service, ok("0.14.0"))
    verify(service.helperOutdated)
    verify(service.helperOutdatedText.indexOf("0.14.0") >= 0)
  }

  function test_a_refused_command_reads_as_an_old_helper() {
    var service = createTemporaryObject(serviceComponent, testCase)
    status(service, null, "omawhatsapp: error: argument command: invalid choice: 'unlink-account'")
    verify(service.helperOutdated)
    compare(service.errorText, service.helperOutdatedText, "no raw argparse error on screen")
  }
}
