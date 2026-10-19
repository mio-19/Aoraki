import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: loginPage
    anchors.fill: parent

    property int authMode: 0 // 0: Phone, 1: QR Code Link

    Connections {
        target: telegramClient
        function onIsLoggedInChanged() {
            if (telegramClient.isLoggedIn) {
                layerStack.pop()
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: loginCol.implicitHeight + Dims.h(12)
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: loginCol
            width: parent.width
            spacing: Dims.h(1.5)

            PageHeader {
                text: "Telegram Login"
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

            // Mode selector (when not mid-authentication)
            Row {
                visible: telegramClient.loginState === "READY" || telegramClient.loginState === "WAIT_PHONE"
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(3)

                Rectangle {
                    width: Dims.w(36)
                    height: Dims.h(8)
                    radius: Dims.w(2)
                    color: loginPage.authMode === 0 ? "#0088CC" : "#26262B"

                    Text {
                        anchors.centerIn: parent
                        text: "Phone Number"
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(2.8)
                        font.bold: loginPage.authMode === 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: loginPage.authMode = 0
                    }
                }

                Rectangle {
                    width: Dims.w(36)
                    height: Dims.h(8)
                    radius: Dims.w(2)
                    color: loginPage.authMode === 1 ? "#0088CC" : "#26262B"

                    Text {
                        anchors.centerIn: parent
                        text: "QR Link"
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(2.8)
                        font.bold: loginPage.authMode === 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            loginPage.authMode = 1
                            telegramClient.requestQrCodeLogin()
                        }
                    }
                }
            }

            // Error display
            Text {
                visible: telegramClient.errorMessage.length > 0
                width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                anchors.horizontalCenter: parent.horizontalCenter
                text: telegramClient.errorMessage
                color: "#E74C3C"
                font.pixelSize: Dims.l(2.6)
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            // State: WAIT_CODE (2nd step of phone auth)
            Column {
                visible: telegramClient.loginState === "WAIT_CODE"
                width: parent.width
                spacing: Dims.h(1.5)

                Text {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Enter 5-digit verification code sent to Telegram or SMS:"
                    color: "#AAAAAA"
                    font.pixelSize: Dims.l(2.8)
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                TextField {
                    id: codeField
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    placeholderText: "Code (e.g. 12345)"
                    onAccepted: {
                        if (codeField.text.length > 0)
                            telegramClient.sendAuthCode(codeField.text)
                    }
                }

                ListItem {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(11)
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if (codeField.text.length > 0)
                            telegramClient.sendAuthCode(codeField.text)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Dims.w(3)
                        color: "#0088CC"

                        Text {
                            anchors.centerIn: parent
                            text: "Verify Code"
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(3.2)
                            font.bold: true
                        }
                    }
                }
            }

            // State: WAIT_PASSWORD (3rd step: 2FA cloud password)
            Column {
                visible: telegramClient.loginState === "WAIT_PASSWORD"
                width: parent.width
                spacing: Dims.h(1.5)

                Text {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Enter your 2FA Cloud Password:"
                    color: "#AAAAAA"
                    font.pixelSize: Dims.l(2.8)
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                TextField {
                    id: passwordField
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    placeholderText: "2FA Password..."
                    echoMode: TextInput.Password
                    onAccepted: {
                        if (passwordField.text.length > 0)
                            telegramClient.sendPassword(passwordField.text)
                    }
                }

                ListItem {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(11)
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if (passwordField.text.length > 0)
                            telegramClient.sendPassword(passwordField.text)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Dims.w(3)
                        color: "#0088CC"

                        Text {
                            anchors.centerIn: parent
                            text: "Submit Password"
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(3.2)
                            font.bold: true
                        }
                    }
                }
            }

            // State: WAIT_QR (QR code / Device Link)
            Column {
                visible: telegramClient.loginState === "WAIT_QR" || (loginPage.authMode === 1 && telegramClient.loginState !== "WAIT_CODE" && telegramClient.loginState !== "WAIT_PASSWORD")
                width: parent.width
                spacing: Dims.h(1.5)

                Text {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Link from Official Telegram Mobile App:"
                    color: "#FFFFFF"
                    font.pixelSize: Dims.l(3.0)
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "1. Open Telegram on phone\n2. Settings → Devices\n3. Tap 'Link Desktop Device'\n4. Confirm login"
                    color: "#AAAAAA"
                    font.pixelSize: Dims.l(2.6)
                    lineHeight: 1.2
                    horizontalAlignment: Text.AlignLeft
                }

                Rectangle {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: Dims.w(2)
                    color: "#1C1C22"

                    Text {
                        anchors.centerIn: parent
                        text: telegramClient.connectionStatus
                        color: "#00A3E0"
                        font.pixelSize: Dims.l(2.8)
                    }
                }
            }

            // State: Phone login form
            Column {
                visible: (telegramClient.loginState === "READY" || telegramClient.loginState === "WAIT_PHONE") && loginPage.authMode === 0
                width: parent.width
                spacing: Dims.h(1.5)

                Text {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Enter your phone number with country code:"
                    color: "#AAAAAA"
                    font.pixelSize: Dims.l(2.8)
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                TextField {
                    id: phoneField
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    placeholderText: "+1234567890"
                    onAccepted: {
                        if (phoneField.text.length > 0)
                            telegramClient.sendPhoneNumber(phoneField.text)
                    }
                }

                ListItem {
                    width: parent.width - (DeviceSpecs.hasRoundScreen ? Dims.w(16) : Dims.w(8))
                    height: Dims.h(11)
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if (phoneField.text.length > 0)
                            telegramClient.sendPhoneNumber(phoneField.text)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Dims.w(3)
                        color: "#0088CC"

                        Text {
                            anchors.centerIn: parent
                            text: "Next"
                            color: "#FFFFFF"
                            font.pixelSize: Dims.l(3.4)
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
