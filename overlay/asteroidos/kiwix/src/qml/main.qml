import QtQuick
import QtQuick.VirtualKeyboard
import org.asteroid.controls

Application {
    id: app

    initialPage: zimManager.hasOpenArchive ? articlePageComponent : libraryPageComponent

    Component {
        id: libraryPageComponent
        LibraryPage {}
    }

    Component {
        id: articlePageComponent
        ArticlePage {}
    }

    Component {
        id: searchPageComponent
        SearchPage {}
    }

    InputPanel {
        id: inputPanel
        z: 999
        x: 0
        y: active ? parent.height - height : parent.height
        width: parent.width

        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }
}
