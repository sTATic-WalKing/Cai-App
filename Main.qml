﻿import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import "." as App

ApplicationWindow {
    id: root
    width: 360
    height: 600
    // width: 768
    // height: 480
    visible: true

    readonly property var typeTexts: [ qsTr("Light") ]
    readonly property var typeIcons: [ "/icons/bulb.svg" ]
    readonly property bool portraitMode: !landscapeCheckBox.checked || root.width < root.height

    header: ToolBar {
        id: toolBar
        height: 104

        ToolButton {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.verticalCenter
            visible: root.portraitMode
            icon.source: "/icons/overview.svg"
            Material.foreground: "white"
            action: Action {
                onTriggered: {
                    drawer.open()
                }
            }
        }
        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.verticalCenter

            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/bluetooth.svg"
                action: Action {
                    onTriggered: {
                        discoverColumnLayout.count = -1
                        discoverDialog.open()

                    }
                }
            }
            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/qr.svg"
            }
            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/settings.svg"
                action: Action {
                    onTriggered: {
                        settingsDialog.open()
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
            contentHeight: height
            currentIndex: swipeView.currentIndex
            spacing: 0
            Material.accent: "white"

            Repeater {
                id: barRepeater
                model: [
                    { "text": qsTr("FURNITURES") },
                    { "text": qsTr("VIEWS") },
                    { "text": qsTr("AUTOS") }
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

        width: Math.min(root.width, root.height) / 3 * 2
        height: root.height
        modal: root.portraitMode
        interactive: root.portraitMode
        position: root.portraitMode ? 0 : 1
        visible: !root.portraitMode
        Material.roundedScale: Material.NotRounded
    }

    SwipeView {
        id: swipeView

        currentIndex: 0
        anchors.fill: parent
        anchors.leftMargin: !root.portraitMode ? drawer.width : undefined

        App.Furnitures {
            id: furnitures
            furnitures: [
                { "address": "11:11:11:11:11:11", "type": 0, "connected": true, "alias": "台灯", "loc": "客厅" },
                { "address": "44:44:44:44:44:44", "type": 0, "connected": false },
                { "address": "22:22:22:22:22:22", "type": 0, "connected": true, "alias": "刚买的台灯" },
                { "address": "33:33:33:33:33:33", "type": 0, "connected": true, "loc": "大房间" }
            ]
            autos: []
        }
        App.Views {
            id: views
        }
        App.Autos {
            id: autos
        }

    }

    Dialog {
        id: settingsDialog
        anchors.centerIn: parent
        width: parent.width
        Material.roundedScale: Material.NotRounded
        modal: true
        focus: true
        title: qsTr("Settings")

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            CheckBox {
                id: landscapeCheckBox
                text: qsTr("Landscape")
                checked: false
                Layout.fillWidth: true
            }
        }
    }

    Dialog {
        id: discoverDialog
        anchors.centerIn: parent
        width: parent.width
        Material.roundedScale: Material.NotRounded
        modal: true
        focus: true
        title: qsTr("Discover")

        ColumnLayout {
            id: discoverColumnLayout
            anchors.fill: parent
            spacing: 10
            property int count
            property real rowHeight: 20

            Label {
                text: {
                    if (discoverColumnLayout.count < 0) {
                        return qsTr("Sending discover request...")
                    }
                    if (discoverColumnLayout.count < 10) {
                        return qsTr("Checking the result and ") + discoverColumnLayout.count + qsTr(" times checked.")
                    }
                    return qsTr("We have checked the result too many times.")
                }
            }
            ProgressBar {
                indeterminate: true
                Layout.fillWidth: true
            }
        }
    }
}
