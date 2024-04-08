import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import "." as App
import "qrc:/common.js" as Common
import "components" as C

ApplicationWindow {
    id: root
    width: 360
    height: 600
    // width: 768
    // height: 480
    visible: true

    Settings {
        id: settings
        property var host: hostTextField.text
    }
    readonly property var typeTexts: [ qsTr("Light") ]
    readonly property var typeIcons: [ "/icons/bulb.svg" ]
    readonly property var stateTexts: [ qsTr("Off"), qsTr("On") ]
    readonly property var stateIcons: [
        [ Material.accent, "orange" ]
    ]

    readonly property bool portraitMode: !landscapeCheckBox.checked || root.width < root.height

    header: ToolBar {
        id: toolBar
        height: 104

        function showToolTip(text) {
            ToolTip.show(text)
        }
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
                id: discoverToolButton
                Material.foreground: "white"
                icon.source: "/icons/bluetooth.svg"
                action: Action {
                    onTriggered: {
                        discoverColumnLayout.count = -1
                        var onPostJSONComplete = function(rsp) {
                            ++discoverColumnLayout.count
                            discoverTimer.before = rsp["count"]
                            discoverTimer.current = discoverTimer.before
                            discoverTimer.start()
                        }
                        Common.postJSON(settings.host + "/discover", {}, true, onPostJSONComplete, root.xhrErrorHandle)
                        discoverDialog.open()
                    }
                }
                Timer {
                    id: discoverTimer
                    repeat: true
                    property int before
                    property int current
                    onTriggered: {
                        console.log("before", before, "current", current)
                        if (before !== current) {
                            stop()
                            discoverDialog.close()
                            furnitures.refresh()
                            return
                        }
                        var onPostJSONComplete = function(rsp) {
                            ++discoverColumnLayout.count
                            current = rsp["count"]
                        }
                        Common.postJSON(settings.host + "/peek", {}, false, onPostJSONComplete, root.xhrErrorHandle)
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
            width: toolBar.width - (root.portraitMode ? 0 : drawer.width)
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
                    width: bar.width / barRepeater.count
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
            furnitures: []
            autos: []
        }
        App.Views {
            id: views
        }
        App.Autos {
            id: autos
        }
    }

    C.Popup {
        id: settingsDialog
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
            TextField {
                id: hostTextField
                placeholderText: qsTr("Host")
                Layout.fillWidth: true
                Component.onCompleted: {
                    text = settings.host
                }
            }
        }
    }

    C.Popup {
        id: discoverDialog
        title: qsTr("Discover")

        ColumnLayout {
            id: discoverColumnLayout
            anchors.fill: parent
            spacing: 10
            property int count

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

    function xhrErrorHandle(xhr) {
        var toolTipText
        if (xhr.status === 0) {
            toolTipText = qsTr("来到了没有网络的荒原~")
        } else {
            toolTipText = qsTr("不知道服务器说了个啥")
        }
        toolBar.showToolTip(toolTipText)
    }
}
