import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import "." as App
import "qrc:/common.js" as J
import "components" as C
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: 360
    height: 600
    visible: true

    function xhrErrorHandle(xhr) {
        var toolTipText
        if (xhr.status === 0) {
            toolTipText = qsTr("Network Error")
        } else if (xhr.status === 412) {
            hashPopup.open()
        } else {
            toolTipText = qsTr("Server Error")
        }
        toolBar.showToolTip(toolTipText)
    }
    function toolBarShowToolTip(text) {
        toolBar.showToolTip(text)
    }
    function get_hash() {
        var related_configs = []
        for (var i = 0; i < root.furnitures.length; ++i) {
            var related_config = {}
            related_config["address"] = root.furnitures[i]["address"]
            related_config["connected"] = root.furnitures[i]["connected"]
            related_config["state"] = root.furnitures[i]["state"]
            related_config["type"] = root.furnitures[i]["type"]
            related_configs.push(related_config)
        }
        related_configs.sort(function(a, b) { return a["address"] < b["address"] })
        var view_uids = []
        for (i = 0; i < root.views.length; ++i) {
            view_uids.push(root.views[i]["uid"])
        }
        view_uids.sort()
        var auto_uids = []
        for (i = 0; i < root.autos.length; ++i) {
            auto_uids.push(root.autos[i]["uid"])
        }
        auto_uids.sort()
        var str = JSON.stringify([ related_configs, view_uids, auto_uids ]).replace(" ", "")
        var hashed = Qt.md5(str)
        return hashed
    }

    Settings {
        id: settings
        property string host: hostTextField.text
    }

    readonly property var typeTexts: [ qsTr("Light") ]
    readonly property var typeIcons: [ "/icons/bulb.svg" ]
    readonly property var stateTexts: [ qsTr("Off"), qsTr("On") ]
    readonly property var stateIcons: [
        [ Material.accent, "orange" ]
    ]
    readonly property var monthsText: [ qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"), qsTr("May"), qsTr("June"), qsTr("July"), qsTr("August"), qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December") ]
    readonly property var unitsOfTime: [ qsTr("Millisecond"), qsTr("Second"), qsTr("Minute"), qsTr("Hour"), qsTr("Day"), qsTr("Week"), qsTr("Month"), qsTr("Year") ]
    readonly property color pink: "#E91E63"
    readonly property real commonSpacing: 10
    readonly property real headerHeight: 100
    readonly property real roundedSize: 32

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

    header: ToolBar {
        id: toolBar
        height: root.headerHeight

        function showToolTip(text) {
            ToolTip.show(text)
        }
        RowLayout {
            id: toolBarRowLayout
            anchors.left: parent.left
            anchors.top: parent.top
            height: 55
            ToolButton {
                visible: root.portraitMode
                icon.source: "/icons/overview.svg"
                Material.foreground: "white"
                action: Action {
                    onTriggered: {
                        drawer.open()
                    }
                }
            }
            ToolButton {
                icon.source: refreshTimer.running ? "/icons/sync.svg" : "/icons/unsync.svg"
                Material.foreground: "white"
                action: Action {
                    onTriggered: {
                        refreshPopup.open()
                    }
                }
            }
        }
        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            height: toolBarRowLayout.height

            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/bluetooth.svg"
                action: Action {
                    onTriggered: {
                        discoverPopup.open()
                    }
                }
            }
            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/qr.svg"
                action: Action {
                    onTriggered: {
                        fileDialog.open()
                    }
                }
            }
            ToolButton {
                Material.foreground: "white"
                icon.source: "/icons/settings.svg"
                action: Action {
                    onTriggered: {
                        settingsPopup.open()
                    }
                }
            }
        }

        TabBar {
            id: bar
            width: toolBar.width - (root.portraitMode ? 0 : drawer.width)
            height: toolBar.height - toolBarRowLayout.height
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

        width: root.portraitMode ? root.width / 3 * 2 : root.width / 3 * 1
        height: root.height
        modal: root.portraitMode
        interactive: root.portraitMode
        position: root.portraitMode ? 0 : 1
        visible: !root.portraitMode
        // Material.roundedScale: Material.NotRounded

        App.Overview {
            anchors.fill: parent
        }
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
        id: settingsPopup
        title: qsTr("Settings")

        ColumnLayout {
            anchors.fill: parent
            spacing: root.commonSpacing

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
        id: discoverPopup
        title: qsTr("Discover")
        property var xhrs: []
        function onXHRError(xhr) {
            close()
            root.xhrErrorHandle(xhr)
        }

        onOpened: {
            discoverColumnLayout.count = -1
            var onPostJSONComplete = function(rsp) {
                ++discoverColumnLayout.count
                discoverTimer.before = rsp["count"]
                discoverTimer.start()
            }
            J.postJSON(settings.host + "/discover", onPostJSONComplete, onXHRError, {}, true, xhrs)
        }
        onClosed: {
            discoverTimer.stop()
            for (var i = 0; i < xhrs.length; ++i) {
                xhrs[i].abort()
            }
        }

        Timer {
            id: discoverTimer
            interval: 2000
            property int before
            onTriggered: {
                var onPostJSONComplete = function(rsp) {
                    ++discoverColumnLayout.count
                    if (before !== rsp["count"]) {
                        var latest = rsp["latest"]
                        if (latest === "") {
                            discoverPopup.close()
                            toolBarShowToolTip(qsTr("No new furnitures found."))
                        } else {
                            discoverColumnLayout.count = -11
                            var onInnerPostJSONComplete = function(rsp) {
                                J.updateAndNotify(root, "furnitures", "address", rsp)
                                discoverPopup.close()
                            }
                            J.postJSON(settings.host + "/config", onInnerPostJSONComplete, discoverPopup.onXHRError, { address: latest }, false, discoverPopup.xhrs)
                        }
                    } else {
                        start()
                    }
                }
                J.postJSON(settings.host + "/peek", onPostJSONComplete, discoverPopup.onXHRError, {}, false, discoverPopup.xhrs)
            }
        }
        ColumnLayout {
            id: discoverColumnLayout
            anchors.fill: parent
            spacing: root.commonSpacing
            property int count

            Label {
                text: {
                    if (discoverColumnLayout.count < -10) {
                        return qsTr("Downloading the config...")
                    }
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

    C.Popup {
        id: hashPopup
        title: qsTr("Unsynchronized")
        standardButtons: Dialog.Ok
        onAccepted: {
            refreshPopup.open()
        }
        onOpened: {
            refreshTimer.stop()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: root.commonSpacing

            Label {
                text: qsTr("Press OK to refresh, and then redo what you want.")
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }

    C.Popup {
        id: refreshPopup
        title: qsTr("Refresh")
        property var xhrs: []
        property int count

        function updateCount() {
            ++count
            if (count === 3) {
                close()
                refreshTimer.start()
            }
        }

        function onDownloadConfigsComplete(list) {
            root.furnitures = list
            updateCount()
        }
        function onDownloadViewsComplete(list) {
            root.views = list
            updateCount()
        }
        function onDownloadAutosComplete(list) {
            root.autos = list
            updateCount()
        }

        onOpened: {
            refreshTimer.stop()
            xhrs = []
            count = 0
            J.downloadModelData(settings.host, "config", "address", onDownloadConfigsComplete, root.xhrErrorHandle, xhrs)
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
            spacing: root.commonSpacing

            Label {
                text: qsTr("We are refreshing all the data.")
            }
            ProgressBar {
                indeterminate: true
                Layout.fillWidth: true
            }
        }
        Timer {
            id: refreshTimer
            interval: 6 * 1000
            onTriggered: {
                var onPostJsonComplete = function(rsp) {
                    if (rsp["hash"] !== root.get_hash()) {
                        refreshPopup.open()
                    } else {
                        start()
                    }
                }
                J.postJSON(settings.host + "/ping", onPostJsonComplete, root.xhrErrorHandle, {}, false)
            }
        }
    }
    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    }

}
