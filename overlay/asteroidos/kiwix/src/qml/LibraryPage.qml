import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: libraryPage
    anchors.fill: parent

    Column {
        anchors.fill: parent

        PageHeader {
            id: header
            text: "Kiwix"
            width: parent.width

            IconButton {
                anchors.right: parent.right
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(9)
                height: width
                iconName: "ios-refresh"
                onClicked: zimManager.scanArchives()
            }
        }

        // Empty state view
        Item {
            id: emptyState
            visible: zimManager.archives.length === 0
            width: parent.width
            height: parent.height - header.height

            Column {
                anchors.centerIn: parent
                width: parent.width * 0.82
                spacing: Dims.h(2)

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "ios-book-outline"
                    width: Dims.w(14)
                    height: width
                    color: "#00A3E0"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No ZIM Books Found"
                    color: "#FFFFFF"
                    font.pixelSize: Dims.l(4.0)
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Place .zim files into /var/lib/kiwix or ~/.local/share/kiwix"
                    color: "#AAAAAA"
                    font.pixelSize: Dims.l(3.0)
                    wrapMode: Text.Wrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scan"
                    onClicked: zimManager.scanArchives()
                }
            }
        }

        // Archive List
        ListView {
            id: archivesList
            visible: zimManager.archives.length > 0
            width: parent.width
            height: parent.height - header.height
            clip: true
            model: zimManager.archives
            boundsBehavior: Flickable.DragOverBounds

            header: Item {
                width: archivesList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(4) : Dims.h(1)
            }

            footer: Item {
                width: archivesList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(10) : Dims.h(3)
            }

            delegate: ListItem {
                id: itemDelegate
                width: archivesList.width
                height: Dims.h(16)

                onClicked: {
                    if (zimManager.openArchive(modelData.filePath)) {
                        layerStack.push(articlePageComponent)
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    spacing: Dims.w(3)

                    Rectangle {
                        width: Dims.w(11)
                        height: width
                        radius: Dims.w(2.5)
                        color: "#0078B7"
                        anchors.verticalCenter: parent.verticalCenter

                        Icon {
                            anchors.centerIn: parent
                            name: "ios-book"
                            width: Dims.w(6)
                            height: width
                            color: "#FFFFFF"
                        }
                    }

                    Column {
                        width: parent.width - Dims.w(15)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Dims.h(0.4)

                        Text {
                            text: modelData.title
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(3.6)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: (modelData.articleCount > 0 ? (modelData.articleCount + " articles • ") : "") + modelData.sizeStr
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
}
