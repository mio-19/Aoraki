import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: browserPage
    anchors.fill: parent

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
                        if (webClient.canGoBack) {
                            webClient.goBack()
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
                    text: webClient.url.toString()
                    font.pixelSize: Dims.l(3.2)
                    inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase

                    onAccepted: {
                        var input = text.trim()
                        if (input.length === 0) return
                        webClient.load(input)
                        focus = false
                    }
                }

                IconButton {
                    id: reloadBtn
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: webClient.loading ? "ios-close" : "ios-refresh"
                    onClicked: {
                        if (webClient.loading) {
                            webClient.stop()
                        } else {
                            webClient.reload()
                        }
                    }
                }
            }
        }

        // Progress indicator
        Rectangle {
            id: progressBar
            width: parent.width * (webClient.loadProgress / 100.0)
            height: Dims.h(0.8)
            color: "#00E5FF"
            visible: webClient.loading
        }

        // Native Flickable web content view
        Flickable {
            id: scrollArea
            width: parent.width
            height: parent.height - headerArea.height - (progressBar.visible ? progressBar.height : 0)
            contentWidth: width
            contentHeight: contentText.paintedHeight + Dims.h(10)
            clip: true
            boundsBehavior: Flickable.DragOverBounds

            Text {
                id: contentText
                width: scrollArea.width - (DeviceSpecs.hasRoundScreen ? Dims.w(14) : Dims.w(6))
                anchors.horizontalCenter: parent.horizontalCenter
                text: webClient.html
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                font.pixelSize: Dims.l(3.4)

                onLinkActivated: function(link) {
                    webClient.load(link)
                }
            }
        }
    }
}
