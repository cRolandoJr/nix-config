import QtQuick
import Quickshell

ShellRoot {
  Component.onCompleted: {
    // Compila la cadena completa que el Loader del selector carga bajo demanda.
    var files = ["wallpaper/WallpaperSelector.qml",
                 "wallpaper/BrowseSurface.qml",
                 "wallpaper/WallhavenBrowser.qml",
                 "wallpaper/SliceDelegate.qml",
                 "wallpaper/FilterBar.qml"]
    var bad = 0
    for (var i = 0; i < files.length; i++) {
      var c = Qt.createComponent(files[i], Component.PreferSynchronous)
      if (c.status === Component.Error) {
        bad++
        console.log("VALIDATE FAIL " + files[i] + " :: " + c.errorString())
      } else {
        console.log("VALIDATE OK   " + files[i])
      }
    }
    console.log("VALIDATE TOTAL fallos=" + bad)
  }
}
