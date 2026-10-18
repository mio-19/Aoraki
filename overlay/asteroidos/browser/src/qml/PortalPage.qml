import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: portalPage
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + Dims.h(10)
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: Dims.h(2)

            PageHeader {
                text: "Web"
                width: parent.width
            }

            // Search input field using Asteroid TextField (triggers Asteroid virtual keyboard)
            Item {
                width: parent.width
                height: Dims.h(12)

                TextField {
                    id: searchInput
                    anchors.centerIn: parent
                    width: DeviceSpecs.hasRoundScreen ? Dims.w(80) : Dims.w(90)
                    height: Dims.h(10)
                    placeholderText: "Search or URL..."
                    font.pixelSize: Dims.l(3.2)
                    inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase

                    onAccepted: {
                        var input = text.trim()
                        if (input.length === 0) return
                        var target = ""
                        if (input.indexOf("://") !== -1 || input.indexOf("about:") === 0) {
                            target = input
                        } else if (input.indexOf(".") !== -1 && input.indexOf(" ") === -1) {
                            target = "https://" + input
                        } else {
                            target = "https://html.duckduckgo.com/html/?q=" + encodeURIComponent(input)
                        }
                        app.openUrl(target)
                        focus = false
                    }
                }
            }

            // Quick Access Tiles Grid
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                spacing: Dims.w(3)

                // DuckDuckGo Tile
                ListItem {
                    width: DeviceSpecs.hasRoundScreen ? Dims.w(38) : Dims.w(43)
                    height: Dims.h(14)
                    onClicked: app.openUrl("https://html.duckduckgo.com")

                    Column {
                        anchors.centerIn: parent
                        spacing: Dims.h(0.5)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🔍"
                            font.pixelSize: Dims.l(4.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "DuckDuckGo"
                            color: "#F0F4F8"
                            font.pixelSize: Dims.l(2.6)
                            font.bold: true
                        }
                    }
                }

                // Wikipedia Mobile Tile
                ListItem {
                    width: DeviceSpecs.hasRoundScreen ? Dims.w(38) : Dims.w(43)
                    height: Dims.h(14)
                    onClicked: app.openUrl("https://en.m.wikipedia.org")

                    Column {
                        anchors.centerIn: parent
                        spacing: Dims.h(0.5)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📖"
                            font.pixelSize: Dims.l(4.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Wikipedia"
                            color: "#F0F4F8"
                            font.pixelSize: Dims.l(2.6)
                            font.bold: true
                        }
                    }
                }

                // Kiwix Local Reader Tile
                ListItem {
                    width: DeviceSpecs.hasRoundScreen ? Dims.w(38) : Dims.w(43)
                    height: Dims.h(14)
                    onClicked: app.openUrl("http://127.0.0.1:8080")

                    Column {
                        anchors.centerIn: parent
                        spacing: Dims.h(0.5)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📚"
                            font.pixelSize: Dims.l(4.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Kiwix Offline"
                            color: "#F0F4F8"
                            font.pixelSize: Dims.l(2.6)
                            font.bold: true
                        }
                    }
                }

                // AsteroidOS Wiki Tile
                ListItem {
                    width: DeviceSpecs.hasRoundScreen ? Dims.w(38) : Dims.w(43)
                    height: Dims.h(14)
                    onClicked: app.openUrl("https://asteroidos.org/wiki/")

                    Column {
                        anchors.centerIn: parent
                        spacing: Dims.h(0.5)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "☄️"
                            font.pixelSize: Dims.l(4.5)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "AsteroidOS"
                            color: "#F0F4F8"
                            font.pixelSize: Dims.l(2.6)
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
