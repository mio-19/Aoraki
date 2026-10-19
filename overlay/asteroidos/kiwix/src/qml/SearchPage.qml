import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: searchPage
    anchors.fill: parent

    Column {
        anchors.fill: parent

        // Search Input Header
        Item {
            id: searchHeader
            width: parent.width
            height: Dims.h(15)

            Row {
                anchors.fill: parent
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                spacing: Dims.w(2)

                IconButton {
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "ios-arrow-back"
                    onClicked: layerStack.pop()
                }

                TextField {
                    id: searchField
                    width: parent.width - Dims.w(11)
                    height: Dims.h(10)
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Search..."
                    focus: true
                    onTextChanged: zimManager.search(text)
                    onAccepted: {
                        if (zimManager.searchResults.length > 0) {
                            var first = zimManager.searchResults[0]
                            zimManager.openPath(first.path)
                            layerStack.pop()
                        }
                    }
                }
            }
        }

        // Suggestions List
        ListView {
            id: resultsList
            width: parent.width
            height: parent.height - searchHeader.height
            clip: true
            model: zimManager.searchResults
            boundsBehavior: Flickable.DragOverBounds

            header: Item {
                width: resultsList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(2) : Dims.h(1)
            }

            footer: Item {
                width: resultsList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(10) : Dims.h(3)
            }

            delegate: ListItem {
                id: resDelegate
                width: resultsList.width
                height: Dims.h(14)

                onClicked: {
                    zimManager.openPath(modelData.path)
                    layerStack.pop()
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    spacing: Dims.w(3)

                    Icon {
                        name: "ios-document-outline"
                        width: Dims.w(6)
                        height: width
                        color: "#00A3E0"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - Dims.w(10)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Dims.h(0.3)

                        Text {
                            text: modelData.title
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(3.4)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            visible: modelData.snippet && modelData.snippet.length > 0
                            text: modelData.snippet || ""
                            color: "#888888"
                            font.pixelSize: Dims.l(2.6)
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        visible: zimManager.searchResults.length === 0
        width: parent.width * 0.8

        Column {
            anchors.centerIn: parent
            spacing: Dims.h(1)

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: searchField.text.length > 0 ? "ios-search" : "ios-book-outline"
                width: Dims.w(12)
                height: width
                color: "#555555"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: searchField.text.length > 0 ? "No articles found" : "Type to search articles"
                color: "#777777"
                font.pixelSize: Dims.l(3.2)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
