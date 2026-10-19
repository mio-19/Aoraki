import QtQuick
import QtQuick.VirtualKeyboard
import org.asteroid.controls
import org.asteroid.utils

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
        webClient.load(url)
        layerStack.push(browserPageComponent)
    }

    InputPanel {
        id: inputPanel
        z: 999
        x: 0
        y: active ? parent.height - height : parent.height
        width: parent.width

        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }
}
