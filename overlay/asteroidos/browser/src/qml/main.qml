import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import QtWebEngine

Application {
    id: app

    centerColor: "#00E5FF"
    outerColor: "#000B14"

    Component { id: browserPageComponent; BrowserPage { } }
    Component { id: portalPageComponent; PortalPage { } }

    LayerStack {
        id: layerStack
        anchors.fill: parent
        firstPage: (initialUrl && initialUrl.length > 0) ? browserPageComponent : portalPageComponent
    }

    function openUrl(url) {
        initialUrl = url
        layerStack.push(browserPageComponent)
    }
}
