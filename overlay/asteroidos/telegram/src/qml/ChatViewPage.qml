import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: chatViewPage
    anchors.fill: parent

    Column {
        anchors.fill: parent

        // Page Header with back button
        Item {
            id: headerArea
            width: parent.width
            height: Dims.h(14)

            IconButton {
                id: backButton
                anchors.left: parent.left
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(9)
                height: width
                iconName: "ios-arrow-back"
                onClicked: layerStack.pop()
            }

            Text {
                anchors.left: backButton.right
                anchors.leftMargin: Dims.w(2)
                anchors.right: parent.right
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                text: telegramClient.currentChatTitle
                color: "#FFFFFF"
                font.pixelSize: Dims.l(3.8)
                font.bold: true
                elide: Text.ElideRight
            }
        }

        // Messages List
        ListView {
            id: messageList
            width: parent.width
            height: parent.height - headerArea.height - inputArea.height
            clip: true
            model: messageModel
            boundsBehavior: Flickable.DragOverBounds
            spacing: Dims.h(1.2)

            onCountChanged: {
                Qt.callLater(function() {
                    messageList.positionViewAtEnd()
                })
            }

            header: Item {
                width: messageList.width
                height: Dims.h(2)
            }

            footer: Item {
                width: messageList.width
                height: Dims.h(2)
            }

            delegate: Item {
                width: messageList.width
                height: bubbleRect.height + (model.isOutgoing ? 0 : senderText.implicitHeight + Dims.h(0.4))

                Text {
                    id: senderText
                    visible: !model.isOutgoing
                    text: model.senderName
                    color: "#00A3E0"
                    font.pixelSize: Dims.l(2.6)
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(4)
                }

                Rectangle {
                    id: bubbleRect
                    anchors.top: senderText.visible ? senderText.bottom : parent.top
                    anchors.topMargin: Dims.h(0.4)
                    anchors.right: model.isOutgoing ? parent.right : undefined
                    anchors.rightMargin: model.isOutgoing ? (DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)) : 0
                    anchors.left: model.isOutgoing ? undefined : parent.left
                    anchors.leftMargin: model.isOutgoing ? 0 : (DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4))

                    width: Math.min(messageText.implicitWidth + Dims.w(6) + timeLabel.implicitWidth, messageList.width * 0.78)
                    height: messageText.implicitHeight + Dims.h(3.2)
                    radius: Dims.w(3)
                    color: model.isOutgoing ? "#0078B7" : "#26262B"

                    Text {
                        id: messageText
                        anchors.left: parent.left
                        anchors.leftMargin: Dims.w(3)
                        anchors.top: parent.top
                        anchors.topMargin: Dims.h(1.4)
                        anchors.right: timeLabel.left
                        anchors.rightMargin: Dims.w(2)
                        text: model.text
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(3.2)
                        wrapMode: Text.Wrap
                    }

                    Text {
                        id: timeLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Dims.w(2.5)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Dims.h(1.0)
                        text: model.time
                        color: model.isOutgoing ? "#BEE3F8" : "#888888"
                        font.pixelSize: Dims.l(2.2)
                    }
                }
            }
        }

        // Bottom Input Area
        Item {
            id: inputArea
            width: parent.width
            height: Dims.h(15)

            Rectangle {
                anchors.fill: parent
                color: "#1A1A1E"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                spacing: Dims.w(2)

                // Quick reply button
                IconButton {
                    id: quickReplyBtn
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "ios-flash"
                    onClicked: layerStack.push(quickRepliesPageComponent)
                }

                // Text field
                TextField {
                    id: inputField
                    width: parent.width - quickReplyBtn.width - sendBtn.width - Dims.w(4)
                    height: Dims.h(10)
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Type..."
                    onAccepted: {
                        if (inputField.text.length > 0) {
                            telegramClient.sendMessage(inputField.text)
                            inputField.text = ""
                        }
                    }
                }

                // Send button
                IconButton {
                    id: sendBtn
                    width: Dims.w(9)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "ios-send"
                    onClicked: {
                        if (inputField.text.length > 0) {
                            telegramClient.sendMessage(inputField.text)
                            inputField.text = ""
                        }
                    }
                }
            }
        }
    }
}
