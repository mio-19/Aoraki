import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: quickRepliesPage
    anchors.fill: parent

    Column {
        anchors.fill: parent

        PageHeader {
            id: header
            text: "Quick Reply"
            width: parent.width

            IconButton {
                anchors.left: parent.left
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(9)
                height: width
                iconName: "ios-arrow-back"
                onClicked: layerStack.pop()
            }
        }

        ListView {
            id: replyList
            width: parent.width
            height: parent.height - header.height - addRow.height
            clip: true
            boundsBehavior: Flickable.DragOverBounds

            header: Item {
                width: replyList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(2) : Dims.h(1)
            }

            footer: Item {
                width: replyList.width
                height: Dims.h(2)
            }

            model: telegramClient.quickReplies

            delegate: ListItem {
                width: replyList.width
                height: Dims.h(12)

                onClicked: {
                    telegramClient.sendQuickReply(modelData)
                    layerStack.pop()
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    spacing: Dims.w(3)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(3.4)
                    }
                }
            }
        }

        // Add custom quick reply row
        Item {
            id: addRow
            width: parent.width
            height: Dims.h(13)

            Rectangle {
                anchors.fill: parent
                color: "#16161A"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                spacing: Dims.w(2)

                TextField {
                    id: customReplyField
                    width: parent.width - addBtn.width - Dims.w(3)
                    height: Dims.h(9)
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "New quick reply..."
                    onAccepted: {
                        if (customReplyField.text.trim().length > 0) {
                            telegramClient.addQuickReply(customReplyField.text)
                            customReplyField.text = ""
                        }
                    }
                }

                IconButton {
                    id: addBtn
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "ios-add"
                    onClicked: {
                        if (customReplyField.text.trim().length > 0) {
                            telegramClient.addQuickReply(customReplyField.text)
                            customReplyField.text = ""
                        }
                    }
                }
            }
        }
    }
}
