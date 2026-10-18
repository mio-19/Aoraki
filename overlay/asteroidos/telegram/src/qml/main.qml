import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: "#0088CC"
    outerColor: "#000B14"

    Component { id: chatsPageComponent; ChatsPage { } }
    Component { id: chatViewPageComponent; ChatViewPage { } }
    Component { id: quickRepliesPageComponent; QuickRepliesPage { } }
    Component { id: loginPageComponent; LoginPage { } }
    Component { id: settingsPageComponent; SettingsPage { } }

    LayerStack {
        id: layerStack
        anchors.fill: parent
        firstPage: chatsPageComponent
    }

    Connections {
        target: telegramClient
        function onMessageReceived(title, text) {
            // Optional feedback or notification alert
        }
    }
}
