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
            height: parent.height - header.height
            clip: true
            boundsBehavior: Flickable.DragOverBounds

            header: Item {
                width: replyList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(4) : Dims.h(1)
            }

            footer: Item {
                width: replyList.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(10) : Dims.h(3)
            }

            model: ListModel {
                ListElement { replyText: "👍 OK" }
                ListElement { replyText: "❤️ Got it!" }
                ListElement { replyText: "🏃 On my way!" }
                ListElement { replyText: "⏰ In 10 minutes" }
                ListElement { replyText: "❌ Can't talk right now" }
                ListElement { replyText: "👋 Hi there!" }
                ListElement { replyText: "☕ Coffee later?" }
                ListElement { replyText: "🎉 Sounds great!" }
            }

            delegate: ListItem {
                width: replyList.width
                height: Dims.h(13)

                onClicked: {
                    telegramClient.sendQuickReply(model.replyText)
                    layerStack.pop()
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(5)
                    spacing: Dims.w(3)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.replyText
                        color: "#FFFFFF"
                        font.pixelSize: Dims.l(3.6)
                    }
                }
            }
        }
    }
}
