import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "MushroomModel.js" as MushroomModel

BarWidget {
  id: root
  moduleName: "bk.mushroom"

  property var mushroomData: null
  property bool showAlways: false
  property string locationName: "Sandnes"
  property real latitude: 58.85244
  property real longitude: 5.73521

  readonly property bool isFavorable: mushroomData && (mushroomData.score >= 30 || mushroomData.alert)
  visible: showAlways || isFavorable
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: {
    root.refresh()
  }

  function refresh() {
    if (!fetchProc.running) {
      fetchProc.command = [
        "curl", "-fsS", "--max-time", "6",
        "https://api.open-meteo.com/v1/forecast?latitude=" + encodeURIComponent(String(root.latitude))
          + "&longitude=" + encodeURIComponent(String(root.longitude))
          + "&current=temperature_2m,relative_humidity_2m,dew_point_2m,precipitation"
          + "&past_days=3&daily=precipitation_sum,temperature_2m_max,temperature_2m_min"
          + "&timezone=auto"
      ]
      fetchProc.running = true
    }
  }

  function updateLocationFromJson(raw) {
    try {
      if (!raw) return
      var obj = JSON.parse(raw)
      if (obj.name) root.locationName = obj.name
      if (!isNaN(parseFloat(obj.latitude))) root.latitude = parseFloat(obj.latitude)
      if (!isNaN(parseFloat(obj.longitude))) root.longitude = parseFloat(obj.longitude)
    } catch (e) {
      // Keep defaults
    }
  }

  function sendAlertNotification() {
    if (!mushroomData) {
      if (root.bar) root.bar.run("omarchy-notification-send -g '🍄' 'Mushroom Alert' 'Fetching latest weather conditions...'")
      return
    }

    var headline = "Mushroom Outlook: " + mushroomData.level + " (" + mushroomData.score + "/100)"
    var advice = mushroomData.alert
      ? "⭐ Ideal conditions for chanterelles & autumn fungi!"
      : (mushroomData.score >= 30 ? "🌿 Conditions are fair; keep an eye on upcoming rain." : "🍂 Dry conditions for mushroom growth.")

    var desc = "📍 " + root.locationName + "\\n"
             + "🌧️ Rain (72h): " + mushroomData.rain3d + " mm\\n"
             + "🌡️ Temp: " + mushroomData.temp + "°C · RH: " + mushroomData.rh + "% · Dew: " + mushroomData.dew + "°C\\n"
             + advice

    var cmd = "omarchy-notification-send -g '🍄' '" + headline.replace(/'/g, "") + "' '" + desc.replace(/'/g, "") + "'"
    if (root.bar) {
      root.bar.run(cmd)
    }
  }

  IpcHandler {
    target: "bk.mushroom"

    function refresh(): void {
      root.refresh()
    }

    function notify(): void {
      root.sendAlertNotification()
    }
  }

  property FileView locationFile: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      root.updateLocationFromJson(text())
      root.refresh()
    }
    onLoadFailed: {
      root.refresh()
    }
  }

  Process {
    id: fetchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        try {
          var parsed = JSON.parse(raw)
          root.mushroomData = MushroomModel.evaluateConditions(parsed)
          console.log("bk.mushroom updated: score=" + root.mushroomData.score + " level=" + root.mushroomData.level)
        } catch (e) {
          // Keep previous data
        }
      }
    }
  }

  // Auto-refresh every 30 minutes
  Timer {
    interval: 1800000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.mushroomData ? root.mushroomData.label : "🍄"
    active: root.mushroomData ? root.mushroomData.alert : false
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: root.mushroomData
      ? ("Mushroom Foraging: " + root.mushroomData.level + " (" + root.mushroomData.score + "/100)\n"
         + "Rain 72h: " + root.mushroomData.rain3d + "mm | RH: " + root.mushroomData.rh + "% | Temp: " + root.mushroomData.temp + "°C\n"
         + "Click for details | Right-click to refresh")
      : "Mushroom Alert: Checking conditions..."

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) {
        root.refresh()
      } else {
        root.sendAlertNotification()
      }
    }
  }
}
