import QtQuick
import QtQuick.VirtualKeyboard

KeyboardLayout {
    id: zhHKLayout
    inputMode: InputEngine.InputMode.Pinyin

    function createInputMethod() {
        return Qt.createQmlObject('import QtQuick; import QtQuick.VirtualKeyboard.Plugins.Rime; RimeInputMethod { Component.onCompleted: selectSchema("jyutping") }', parent, "inputMethod.qml")
    }

    keyWeight: 160
    KeyboardRow {
        Key { key: Qt.Key_Q; text: "q" }
        Key { key: Qt.Key_W; text: "w" }
        Key { key: Qt.Key_E; text: "e" }
        Key { key: Qt.Key_R; text: "r" }
        Key { key: Qt.Key_T; text: "t" }
        Key { key: Qt.Key_Y; text: "y" }
        Key { key: Qt.Key_U; text: "u" }
        Key { key: Qt.Key_I; text: "i" }
        Key { key: Qt.Key_O; text: "o" }
        Key { key: Qt.Key_P; text: "p" }
        BackspaceKey {}
    }
    KeyboardRow {
        FillerKey { weight: 56 }
        Key { key: Qt.Key_A; text: "a" }
        Key { key: Qt.Key_S; text: "s" }
        Key { key: Qt.Key_D; text: "d" }
        Key { key: Qt.Key_F; text: "f" }
        Key { key: Qt.Key_G; text: "g" }
        Key { key: Qt.Key_H; text: "h" }
        Key { key: Qt.Key_J; text: "j" }
        Key { key: Qt.Key_K; text: "k" }
        Key { key: Qt.Key_L; text: "l" }
        EnterKey { weight: 283 }
    }
    KeyboardRow {
        keyWeight: 156
        ShiftKey {}
        Key { key: Qt.Key_Z; text: "z" }
        Key { key: Qt.Key_X; text: "x" }
        Key { key: Qt.Key_C; text: "c" }
        Key { key: Qt.Key_V; text: "v" }
        Key { key: Qt.Key_B; text: "b" }
        Key { key: Qt.Key_N; text: "n" }
        Key { key: Qt.Key_M; text: "m" }
        Key { key: Qt.Key_Apostrophe; text: "'"; alternativeKeys: "\"`" }
        Key { key: Qt.Key_Comma; text: "，" }
        Key { key: Qt.Key_Period; text: "。" }
    }
    KeyboardRow {
        keyWeight: 154
        SymbolModeKey { weight: 217 }
        ChangeLanguageKey { weight: 154 }
        SpaceKey { weight: 864 }
        HideKeyboardKey { weight: 204 }
    }
}
