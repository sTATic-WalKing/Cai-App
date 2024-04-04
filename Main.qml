import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import "." as App

ApplicationWindow {
    id: window
    width: 360
    height: 768
    // width: 768
    // height: 480
    visible: true

    readonly property bool portraitMode: !landscapeCheckBox.checked || window.width < window.height

    header: ToolBar {
        id: toolBar
        height: 104

        RowLayout {
            spacing: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.verticalCenter
            anchors.leftMargin: !window.portraitMode ? drawer.width : undefined

            ToolButton {
                visible: window.portraitMode
                icon.source: "/icons/overview.svg"
                Material.foreground: "white"
                Layout.alignment: Qt.AlignLeft
                action: Action {
                    onTriggered: {
                        drawer.open()
                    }
                }
            }

            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/settings.svg"
                Layout.alignment: Qt.AlignRight
                action: Action {
                    onTriggered: {
                        menu.open()
                    }
                }

                Menu {
                    id: menu
                    x: parent.width - width
                    transformOrigin: Menu.TopRight

                    Action {
                        text: qsTr("Settings")
                        onTriggered: settingsDialog.open()
                    }
                    Action {
                        text: qsTr("About")
                        onTriggered: aboutDialog.open()
                    }
                }
            }
        }

        TabBar {
            id: bar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.verticalCenter
            anchors.bottom: parent.bottom
            currentIndex: swipeView.currentIndex
            spacing: 0
            Material.accent: "white"

            Repeater {
                id: barRepeater
                model: [
                    { "text": qsTr("FURNITURES"), "iconSource": "/icons/furnitures.svg" },
                    { "text": qsTr("VIEWS"), "iconSource": "/icons/views.svg" },
                    { "text": qsTr("AUTOS"), "iconSource": "/icons/autos.svg" }
                ]

                TabButton {
                    text: modelData["text"]
                    width: toolBar.width / barRepeater.count
                    Material.accent: bar.Material.accent
                    Material.foreground: Qt.tint(Material.primary, "#aaffffff")
                    background: Rectangle {
                        color: Material.primary
                    }
                    onClicked: {
                        swipeView.currentIndex = TabBar.index
                    }
                }
            }
        }
    }

    Drawer {
        id: drawer

        width: Math.min(window.width, window.height) / 3 * 2
        height: window.height
        modal: window.portraitMode
        interactive: window.portraitMode
        position: window.portraitMode ? 0 : 1
        visible: !window.portraitMode
        Material.roundedScale: Material.NotRounded
    }

    SwipeView {
        id: swipeView

        currentIndex: 0
        anchors.fill: parent
        anchors.leftMargin: !window.portraitMode ? drawer.width : undefined

        App.Furnitures {
        }
        App.Views {
        }
        App.Autos {
        }

    }

    Dialog {
        id: settingsDialog
        x: Math.round((window.width - width) / 2)
        y: Math.round(window.height / 6)
        width: Math.round(Math.min(window.width, window.height) / 3 * 2)
        modal: true
        focus: true
        title: qsTr("Settings")

        contentItem: ColumnLayout {
            spacing: 20

            CheckBox {
                id: landscapeCheckBox
                text: qsTr("Landscape")
                checked: false
                Layout.fillWidth: true
            }
        }
    }

    Dialog {
        id: aboutDialog
        modal: true
        focus: true
        title: qsTr("About")
        x: (window.width - width) / 2
        y: window.height / 6
        width: Math.min(window.width, window.height) / 3 * 2
        contentHeight: aboutColumn.height

        Column {
            id: aboutColumn
            spacing: 20

            Label {
                width: aboutDialog.availableWidth
                wrapMode: Label.Wrap
                font.pixelSize: 12
            }
        }
    }
}
