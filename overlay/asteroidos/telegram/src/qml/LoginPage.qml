import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: loginPage
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        contentHeight: loginCol.implicitHeight + Dims.h(12)
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: loginCol
            width: parent.width
            spacing: Dims.h(2)

            PageHeader {
                text: "Login"
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

            Text {
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Enter Telegram Bot Token or Phone Number:"
                color: "#AAAAAA"
                font.pixelSize: Dims.l(2.8)
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            TextField {
                id: tokenField
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                height: Dims.h(11)
                anchors.horizontalCenter: parent.horizontalCenter
                placeholderText: "Token or Phone..."
            }

            ListItem {
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                height: Dims.h(12)
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if (tokenField.text.indexOf(":") !== -1) {
                        telegramClient.loginWithToken(tokenField.text)
                    } else {
                        telegramClient.loginWithPhone(tokenField.text)
                    }
                    layerStack.pop()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Dims.w(3)
                    color: "#0088CC"

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(3.4)
                        font.bold: true
                    }
                }
            }
        }
    }
}
