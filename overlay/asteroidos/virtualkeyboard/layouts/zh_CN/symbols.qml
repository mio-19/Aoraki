import QtQuick
import QtQuick.VirtualKeyboard

KeyboardLayout {
    id: zhCNSymbolsLayout
    inputMode: InputEngine.InputMode.Latin

    keyWeight: 160
    KeyboardRow {
        Key { key: Qt.Key_1; text: "1" }
        Key { key: Qt.Key_2; text: "2" }
        Key { key: Qt.Key_3; text: "3" }
        Key { key: Qt.Key_4; text: "4" }
        Key { key: Qt.Key_5; text: "5" }
        Key { key: Qt.Key_6; text: "6" }
        Key { key: Qt.Key_7; text: "7" }
        Key { key: Qt.Key_8; text: "8" }
        Key { key: Qt.Key_9; text: "9" }
        Key { key: Qt.Key_0; text: "0" }
        BackspaceKey {}
    }
    KeyboardRow {
        FillerKey { weight: 56 }
        Key { key: Qt.Key_At; text: "@" }
        Key { key: Qt.Key_NumberSign; text: "#" }
        Key { key: Qt.Key_Dollar; text: "¥" }
        Key { key: Qt.Key_Percent; text: "%" }
        Key { key: Qt.Key_Ampersand; text: "&" }
        Key { key: Qt.Key_Minus; text: "-" }
        Key { key: Qt.Key_Plus; text: "+" }
        Key { key: Qt.Key_ParenLeft; text: "（" }
        Key { key: Qt.Key_ParenRight; text: "）" }
        EnterKey { weight: 283 }
    }
    KeyboardRow {
        keyWeight: 156
        Key { key: Qt.Key_Asterisk; text: "*" }
        Key { key: Qt.Key_QuoteDbl; text: "“" }
        Key { key: Qt.Key_Apostrophe; text: "’" }
        Key { key: Qt.Key_Colon; text: "：" }
        Key { key: Qt.Key_Semicolon; text: "；" }
        Key { key: Qt.Key_Exclam; text: "！" }
        Key { key: Qt.Key_Question; text: "？" }
        Key { key: Qt.Key_Slash; text: "/" }
        Key { key: Qt.Key_Underscore; text: "_" }
    }
    KeyboardRow {
        keyWeight: 154
        SymbolModeKey { weight: 217 }
        ChangeLanguageKey { weight: 154 }
        SpaceKey { weight: 864 }
        HideKeyboardKey { weight: 204 }
    }
}
