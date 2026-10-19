import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: articlePage
    anchors.fill: parent

    Column {
        anchors.fill: parent

        // Top Control Bar
        Item {
            id: headerBar
            width: parent.width
            height: Dims.h(14)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Dims.w(1.5)

                IconButton {
                    width: Dims.w(9)
                    height: width
                    iconName: "ios-arrow-back"
                    onClicked: {
                        if (zimManager.canGoBack) {
                            zimManager.goBack()
                        } else {
                            layerStack.pop()
                        }
                    }
                }

                IconButton {
                    width: Dims.w(8)
                    height: width
                    iconName: "ios-arrow-forward"
                    opacity: zimManager.canGoForward ? 1.0 : 0.3
                    onClicked: {
                        if (zimManager.canGoForward) {
                            zimManager.goForward()
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width * 0.42
                text: zimManager.currentTitle || "Article"
                color: "#FFFFFF"
                font.pixelSize: Dims.l(3.4)
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Dims.w(1.5)

                IconButton {
                    width: Dims.w(9)
                    height: width
                    iconName: "ios-search"
                    onClicked: layerStack.push(searchPageComponent)
                }

                IconButton {
                    width: Dims.w(9)
                    height: width
                    iconName: "ios-albums-outline"
                    onClicked: layerStack.push(libraryPageComponent)
                }
            }
        }

        // Article Content Scroll Area
        Flickable {
            id: flickable
            width: parent.width
            height: parent.height - headerBar.height
            clip: true
            contentWidth: width
            contentHeight: articleText.implicitHeight + (DeviceSpecs.hasRoundScreen ? Dims.h(16) : Dims.h(8))
            boundsBehavior: Flickable.DragOverBounds

            Text {
                id: articleText
                width: flickable.width - (DeviceSpecs.hasRoundScreen ? Dims.w(14) : Dims.w(6))
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Dims.h(2)
                textFormat: Text.RichText
                text: zimManager.currentHtml
                wrapMode: Text.Wrap
                color: "#FFFFFF"
                onLinkActivated: function(link) {
                    zimManager.openPath(link)
                    flickable.contentY = 0
                }
            }
        }
    }
}
