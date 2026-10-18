import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: settingsPage
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        contentHeight: settingsCol.implicitHeight + Dims.h(12)
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: settingsCol
            width: parent.width
            spacing: Dims.h(1.5)

            PageHeader {
                text: "Settings"
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

            // User Info
            Rectangle {
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                height: Dims.h(15)
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Dims.w(3)
                color: "#1C1C22"

                Column {
                    anchors.centerIn: parent
                    spacing: Dims.h(0.5)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: telegramClient.accountName
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(3.6)
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: telegramClient.connectionStatus
                        color: telegramClient.isLoggedIn ? "#7CA600" : "#888888"
                        font.pixelSize: Dims.l(2.6)
                    }
                }
            }

            // Vibration Toggle
            ListItem {
                width: parent.width
                height: Dims.h(12)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Vibration"
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(3.4)
                    }

                    Switch {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: telegramClient.hapticsEnabled
                        onCheckedChanged: telegramClient.hapticsEnabled = checked
                    }
                }
            }

            // Login / Connect Button
            ListItem {
                width: parent.width
                height: Dims.h(12)
                onClicked: layerStack.push(loginPageComponent)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    spacing: Dims.w(3)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: telegramClient.isLoggedIn ? "Account Details" : "Log In"
                        color: "#00A3E0"
                        font.pixelSize: Dims.l(3.4)
                    }
                }
            }

            // Logout Button
            ListItem {
                visible: telegramClient.isLoggedIn
                width: parent.width
                height: Dims.h(12)
                onClicked: telegramClient.logout()

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    spacing: Dims.w(3)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Log Out"
                        color: "#FF453A"
                        font.pixelSize: Dims.l(3.4)
                    }
                }
            }
        }
    }
}
