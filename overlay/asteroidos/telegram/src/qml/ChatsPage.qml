import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: chatsPage
    anchors.fill: parent

    Column {
        anchors.fill: parent

        PageHeader {
            id: header
            text: "Telegram"
            width: parent.width

            IconButton {
                anchors.right: parent.right
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(10)
                height: width
                iconName: "ios-settings-outline"
                onClicked: layerStack.push(settingsPageComponent)
            }
        }

        ListView {
            id: chatsList
            width: parent.width
            height: parent.height - header.height
            clip: true
            model: chatModel
            boundsBehavior: Flickable.DragOverBounds

            header: Item {
                width: chatsList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(4) : Dims.h(1)
            }

            footer: Item {
                width: chatsList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(10) : Dims.h(3)
            }

            delegate: ListItem {
                id: chatDelegate
                width: chatsList.width
                height: Dims.h(16)

                onClicked: {
                    telegramClient.selectChat(model.chatId, model.title)
                    layerStack.push(chatViewPageComponent)
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    spacing: Dims.w(3)

                    // Avatar Circle
                    Rectangle {
                        width: Dims.w(11)
                        height: width
                        radius: width / 2
                        color: model.avatarColor || "#0088CC"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: (model.title.length > 0 ? model.title[0] : "T").toUpperCase()
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(4)
                            font.bold: true
                        }
                    }

                    // Title & Last Message
                    Column {
                        width: parent.width - Dims.w(14) - (model.unreadCount > 0 ? Dims.w(8) : 0)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Dims.h(0.5)

                        Row {
                            width: parent.width
                            spacing: Dims.w(2)

                            Text {
                                text: model.title
                                color: "#FFFFFF"
                                font.pixelSize: Dims.l(3.8)
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width - timeText.implicitWidth - Dims.w(2)
                            }

                            Text {
                                id: timeText
                                text: model.time
                                color: "#888888"
                                font.pixelSize: Dims.l(2.6)
                            }
                        }

                        Text {
                            text: model.lastMessage
                            color: "#BBBBBB"
                            font.pixelSize: Dims.l(3.0)
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // Unread Count Badge
                    Rectangle {
                        visible: model.unreadCount > 0
                        width: Math.max(Dims.w(5), unreadText.implicitWidth + Dims.w(2))
                        height: Dims.w(5)
                        radius: height / 2
                        color: "#00A3E0"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: unreadText
                            anchors.centerIn: parent
                            text: model.unreadCount > 99 ? "99+" : model.unreadCount.toString()
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(2.4)
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
