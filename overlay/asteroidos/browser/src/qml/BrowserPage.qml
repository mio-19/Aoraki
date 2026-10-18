import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import QtWebEngine

Item {
    id: browserPage
    anchors.fill: parent

    property string currentTargetUrl: (initialUrl && initialUrl.length > 0) ? initialUrl : "file://" + browserShareDir + "/portal.html"

    Column {
        anchors.fill: parent

        // Top Navigation Bar with safe margins for circular smartwatch displays
        Item {
            id: headerArea
            width: parent.width
            height: Dims.h(14)

            Row {
                anchors.fill: parent
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                spacing: Dims.w(2)

                IconButton {
                    id: backBtn
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "ios-arrow-back"
                    onClicked: {
                        if (webView.canGoBack) {
                            webView.goBack()
                        } else {
                            layerStack.pop()
                        }
                    }
                }

                TextField {
                    id: urlInput
                    width: parent.width - backBtn.width - reloadBtn.width - (parent.spacing * 2)
                    height: Dims.h(10)
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Search or URL..."
                    text: webView.url.toString()
                    font.pixelSize: Dims.l(3.2)
                    inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase

                    onAccepted: {
                        var input = text.trim()
                        if (input.length === 0) return
                        if (input.indexOf("://") !== -1 || input.indexOf("about:") === 0) {
                            webView.url = input
                        } else if (input.indexOf(".") !== -1 && input.indexOf(" ") === -1) {
                            webView.url = "https://" + input
                        } else {
                            webView.url = "https://html.duckduckgo.com/html/?q=" + encodeURIComponent(input)
                        }
                        focus = false
                    }
                }

                IconButton {
                    id: reloadBtn
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: webView.loading ? "ios-close" : "ios-refresh"
                    onClicked: {
                        if (webView.loading) {
                            webView.stop()
                        } else {
                            webView.reload()
                        }
                    }
                }
            }
        }

        // Progress indicator
        Rectangle {
            id: progressBar
            width: parent.width * (webView.loadProgress / 100.0)
            height: Dims.h(0.8)
            color: "#00E5FF"
            visible: webView.loading
        }

        // WebEngine View with JavaScript and modern web capabilities
        WebEngineView {
            id: webView
            width: parent.width
            height: parent.height - headerArea.height - (progressBar.visible ? progressBar.height : 0)
            url: browserPage.currentTargetUrl

            settings.javascriptEnabled: true
            settings.autoLoadImages: true
            settings.localContentCanAccessRemoteUrls: true
            settings.localContentCanAccessFileUrls: true
            settings.scrollAnimatorEnabled: true

            zoomFactor: 0.85
        }
    }
}
