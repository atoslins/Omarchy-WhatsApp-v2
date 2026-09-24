import QtQuick

QtObject {
  property string path: ""
  property string content: ""
  signal loaded()
  function text() { return content }
}
