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

            Row {
                anchors.left: parent.left
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Dims.w(1)

                IconButton {
                    width: Dims.w(8)
                    height: width
                    iconName: "ios-refresh"
                    onClicked: telegramClient.refresh()
                }

                IconButton {
                    width: Dims.w(8)
                    height: width
                    iconName: "ios-search"
                    onClicked: {
                        searchBar.visible = !searchBar.visible
                        if (!searchBar.visible) {
                            chatModel.filterQuery = ""
                        }
                    }
                }
            }

            // Connection status pill
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Dims.h(0.4)
                spacing: Dims.w(1)

                Rectangle {
                    width: Dims.w(1.8)
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: telegramClient.connectionStatus === "Connected" ? "#4CAF50" : (telegramClient.connectionStatus === "Offline" ? "#F44336" : "#FF9800")
                }

                Text {
                    text: telegramClient.connectionStatus
                    color: "#888888"
                    font.pixelSize: Dims.l(2.2)
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(9)
                height: width
                iconName: "ios-settings-outline"
                onClicked: layerStack.push(settingsPageComponent)
            }
        }

        // Search Bar (collapsible)
        Item {
            id: searchBar
            visible: false
            width: parent.width
            height: visible ? Dims.h(12) : 0

            TextField {
                id: searchInput
                anchors.centerIn: parent
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                height: Dims.h(9)
                placeholderText: "Search chats..."
                onTextChanged: chatModel.filterQuery = text
            }
        }

        Item {
            id: emptyState
            visible: chatModel.count === 0
            width: parent.width
            height: parent.height - header.height - searchBar.height

            Column {
                anchors.centerIn: parent
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                spacing: Dims.h(1.8)

                Rectangle {
                    width: Dims.w(14)
                    height: width
                    radius: width / 2
                    color: "#0088CC"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✈"
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(5.5)
                    }
                }

                Text {
                    text: telegramClient.isLoggedIn ? "No Conversations" : "Not Logged In"
                    color: "#FFFFFF"
                    font.pixelSize: Dims.l(3.4)
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: telegramClient.isLoggedIn
                          ? "Incoming messages and synchronized chats will appear here."
                          : "Log in with your phone number or QR link to start messaging."
                    color: "#888888"
                    font.pixelSize: Dims.l(2.6)
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                ListItem {
                    visible: !telegramClient.isLoggedIn
                    width: parent.width
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: layerStack.push(loginPageComponent)

                    Rectangle {
                        anchors.fill: parent
                        radius: Dims.w(3)
                        color: "#0088CC"

                        Text {
                            anchors.centerIn: parent
                            text: "Log In"
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(3.2)
                            font.bold: true
                        }
                    }
                }
            }
        }

        ListView {
            id: chatsList
            visible: chatModel.count > 0
            width: parent.width
            height: parent.height - header.height - searchBar.height
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
