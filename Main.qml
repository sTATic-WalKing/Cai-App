import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import "." as App
import "qrc:/common.js" as J
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

    property var furnitures: []
    property var views: []
    property var autos: []

    onFurnituresChanged: {
        J.updateModelData(furnituresListModel, root.furnitures, "furniture", "address")
    }
    onViewsChanged: {
        J.updateModelData(autosListModel, root.views, "view", "uid")
    }

    readonly property bool portraitMode: !landscapeCheckBox.checked || root.width < root.height
    property var currentDate
    Timer {
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            currentDate = new Date()
        }
        Component.onCompleted: {
            start()
        }
    }

    header: ToolBar {
        id: toolBar
        height: 100

        function showToolTip(text) {
            ToolTip.show(text)
        }
        ToolButton {
            id: drawerToolButton
            anchors.left: parent.left
            anchors.top: parent.top
            height: 55
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
            height: drawerToolButton.height

            ToolButton {
                id: discoverToolButton
                Material.foreground: "white"
                icon.source: "/icons/bluetooth.svg"
                action: Action {
                    onTriggered: {
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
                            discoverDialog.close()
                            furnitures.refresh()
                            return
                        }
                        var onPostJSONComplete = function(rsp) {
                            ++discoverColumnLayout.count
                            current = rsp["count"]
                        }
                        var onPostJSONError = function(xhr) {
                            discoverDialog.close()
                            root.xhrErrorHandle(xhr)
                        }
                        J.postJSON(settings.host + "/peek", onPostJSONComplete, onPostJSONError, {}, false)
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
            height: toolBar.height - drawerToolButton.height
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentHeight: height
            currentIndex: swipeView.currentIndex
            spacing: 0
            Material.accent: "white"
            Material.background: Material.primary

            Repeater {
                id: barRepeater
                model: [
                    { "text": qsTr("FURNITURES"), "iconSource": "/icons/furnitures.svg" },
                    { "text": qsTr("AUTOS"), "iconSource": "/icons/autos.svg" },
                ]

                TabButton {
                    text: modelData["text"]
                    width: 110
                    Material.accent: bar.Material.accent
                    Material.foreground: Qt.tint(Material.primary, "#aaffffff")
                    icon.source: {
                        if (Qt.locale().name.indexOf("zh") !== -1) {
                            return modelData["iconSource"]
                        }
                        return undefined
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
            onRefresh: {
                refreshPopup.open()
            }
            model: ListModel {
                id: furnituresListModel
            }
        }
        App.Autos {
            id: autos
            onRefresh: {
                refreshPopup.open()
            }
            model: ListModel {
                id: autosListModel
            }
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
        onOpened: {
            discoverColumnLayout.count = -1
            var onPostJSONComplete = function(rsp) {
                ++discoverColumnLayout.count
                discoverTimer.before = rsp["count"]
                discoverTimer.current = discoverTimer.before
                discoverTimer.start()
            }
            J.postJSON(settings.host + "/discover", onPostJSONComplete, root.xhrErrorHandle)
        }

        onClosed: {
            discoverTimer.stop()
        }

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

    C.Popup {
        id: refreshPopup
        title: qsTr("Refresh")
        property var xhrs

        function onDownloadConfigsComplete(list) {
            root.furnitures = list
            close()
        }
        function downloadConfigs(list) {
            for (var i = 0; i < list.length; ++i) {
                var current = list[i]
                if (!current["connected"]) {
                    continue
                }
                var onInnerPostJsonComplete = function(rsp) {
                    list[J.find(list, "address", current["address"])]["state"] = rsp["state"]
                }
                J.postJSON(settings.host + "/state", onInnerPostJsonComplete, root.xhrErrorHandle, { address: current["address"] }, false, xhrs)
            }
            onDownloadConfigsComplete(list)
        }
        function onDownloadViewsComplete(list) {
            root.views = list
            close()
        }
        function onDownloadAutosComplete(list) {
            root.autos = list
            close()
        }

        onOpened: {
            xhrs = []
            J.downloadModelData(settings.host, "config", "address", downloadConfigs, root.xhrErrorHandle, xhrs)
            J.downloadModelData(settings.host, "view", "uid", onDownloadViewsComplete, root.xhrErrorHandle, xhrs)
            J.downloadModelData(settings.host, "auto", "uid", onDownloadAutosComplete, root.xhrErrorHandle, xhrs)
        }
        onClosed: {
            for (var i = 0; i < xhrs.length; ++i) {
                xhrs[i].abort()
            }
        }

        ColumnLayout {
            id: refreshColumnLayout
            anchors.fill: parent
            spacing: 10

            Label {
                text: qsTr("We are refreshing the furnitures list.")
            }
            ProgressBar {
                indeterminate: true
                Layout.fillWidth: true
            }
        }
    }
}
