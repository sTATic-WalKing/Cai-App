import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as J

C.List {
    id: furnituresList
    property var filters: ({})

    delegate: Component {
        C.Touch {
            buttonWidth: furnituresList.width
            buttonHeight: 60

            buttonContentItem: Item {
                C.Rounded {
                    id: stateRounded
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    icon.source: root.typeIcons[furniture["type"]]
                    highlighted: furniture["state"] !== undefined && furniture["state"] > 0
                    Material.accent: furniture["state"] !== undefined ? root.stateIcons[furniture["type"]][furniture["state"]] : root.stateIcons[furniture["type"]][0]
                    enabled: furniture["state"] !== undefined && furniture["connected"]

                    onClicked: {
                        var onPostJsonComplete = function(rsp) {
                            var index = J.find(root.furnitures, "address", furniture["address"])
                            if (index === -1) {
                                return
                            }
                            var data = root.furnitures[index]
                            data["state"] = rsp["state"]
                            J.updateAndNotify(root, "furnitures", "address", data)
                        }
                        var content = {}
                        content["state"] = furniture["state"] > 0 ? 0 : 1
                        content["address"] = furniture["address"]
                        J.postJSON(settings.host + "/state", onPostJsonComplete, root.xhrErrorHandle, content)
                    }
                }
                C.VFit {
                    id: infoVFit
                    height: 15
                    anchors.left: stateRounded.right
                    anchors.leftMargin: root.commonSpacing
                    anchors.bottom: stateRounded.bottom
                    text: {
                        var ret = ""
                        var entries = Object.entries(furniture)
                        for (var i = 0; i < entries.length; ++i) {
                            if (entries[i][0] === "address" || entries[i][0] === "type" || entries[i][0] === "connected" || entries[i][0] === "state") {
                                continue
                            }
                            if (ret !== "") {
                                ret += qsTr(", ")
                            }
                            ret += entries[i][1]
                        }
                        if (ret === "") {
                            ret = furniture["address"]
                        }
                        return ret
                    }
                }
                C.VFit {
                    id: associatedVFit
                    height: 14
                    anchors.left: infoVFit.left
                    anchors.top: stateRounded.top
                    enabled: associated
                    property bool associated
                    text: {
                        var associatedAutos = J.furnitureFindAssociatedAutos(furniture["address"], root.views, root.autos)
                        associatedAutos.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                        if (associatedAutos.length > 0) {
                            var auto = root.autos[associatedAutos[0]]
                            var states = root.views[J.find(root.views, "uid", auto["view"])]["states"]
                            associated = true
                            return "<font color=\"grey\">" + qsTr("Will be") + "</font> " + root.stateTexts[states[J.find(states, "address", furniture["address"])]["state"]] + "<font color=\"grey\"> " + qsTr("at") + " </font>" + J.date2ShortText(new Date(auto["start"] * 1000))
                        } else {
                            associated = false
                            return "<font color=\"grey\">" + qsTr("No arranged execution") + "</font>"
                        }

                    }

                }

                RowLayout {
                    height: stateRounded.height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: root.commonSpacing
                    layoutDirection: Qt.RightToLeft
                    C.Rounded {
                        highlighted: true
                        icon.source: furniture["connected"] ? "/icons/connected.svg" : "/icons/disconnected.svg"
                        Material.accent: furniture["connected"] ? parent.Material.accent : root.pink
                        onClicked: {
                            if (furniture["connected"]) {
                                disconnectPopup.open()
                            } else {
                                connectPopup.open()
                            }
                        }
                    }
                    C.Rounded {
                        highlighted: furniture["connected"]
                        enabled: furniture["connected"]
                        icon.source: "/icons/config.svg"

                        onClicked: {
                            configPopup.open()
                        }
                    }

                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#eeeeee"
            }
            C.Popup {
                id: configPopup
                title: qsTr("Config")
                standardButtons: Dialog.Ok
                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.commonSpacing

                    TextField {
                        id: aliasTextField
                        placeholderText: qsTr("Alias")
                        Layout.fillWidth: true
                    }
                    TextField {
                        id: locTextField
                        placeholderText: qsTr("Location")
                        Layout.fillWidth: true
                    }
                }
                onAccepted: {
                    if (aliasTextField.text === "" && locTextField.text === "") {
                        root.toolBarShowToolTip(qsTr("Inputs cannot all be empty! "))
                        return
                    }

                    var onPostJsonComplete = function(rsp) {
                        var index = J.find(root.furnitures, "address", furniture["address"])
                        if (index === -1) {
                            return
                        }
                        rsp["state"] = root.furnitures[index]["state"]
                        J.updateAndNotify(root, "furnitures", "address", rsp)
                    }
                    var content = {}
                    content["address"] = furniture["address"]
                    if (aliasTextField.text !== "") {
                        content["alias"] = aliasTextField.text
                    }
                    if (locTextField.text !== "") {
                        content["loc"] = locTextField.text
                    }

                    J.postJSON(settings.host + "/config", onPostJsonComplete, root.xhrErrorHandle, content)
                }
            }
            C.Popup {
                id: disconnectPopup
                title: qsTr("Disconnecting...")
                property var xhrs: []
                onOpened: {
                    var onPostJsonComplete = function(rsp) {
                        close()
                        var index = J.find(root.furnitures, "address", furniture["address"])
                        if (index === -1) {
                            return
                        }
                        var data = root.furnitures[index]
                        data["connected"] = false
                        J.updateAndNotify(root, "furnitures", "address", data)
                    }
                    var content = {}
                    content["address"] = furniture["address"]
                    J.postJSON(settings.host + "/disconnect", onPostJsonComplete, root.xhrErrorHandle, content, true, xhrs)
                }
                onClosed: {
                    for (var i = 0; i < xhrs.length; ++i) {
                        xhrs[i].abort()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.commonSpacing
                    ProgressBar {
                        indeterminate: true
                        Layout.fillWidth: true
                    }
                }
            }
            C.Popup {
                id: connectPopup
                title: qsTr("Connect")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.commonSpacing
                    Label {
                        text: qsTr("Connecting to a specified furniture is not supported, and try Discover button at the top bar.")
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            extraHeight: extraColumnLayout.height + extraColumnLayout.spacing
            extraWidth: extraColumnLayout.width
            ColumnLayout {
                id: extraColumnLayout
                anchors.top: button.bottom
                x: infoVFit.x + buttonContentItem.x
                width: buttonContentItem.width - infoVFit.x
                clip: true

                readonly property real rowHeight: 15
                C.VFit {
                    Layout.preferredHeight: extraColumnLayout.rowHeight
                    text: "<font color=\"grey\">" + qsTr("Address") + qsTr(": ") + "</font>" + furniture["address"]
                }
                C.VFit {
                    Layout.preferredHeight: extraColumnLayout.rowHeight
                    text: {
                        var furnitureAlias = furniture["alias"]
                        if (furnitureAlias === undefined) {
                            furnitureAlias = "<font color=\"grey\">" + qsTr("Not configured") + "</font>"
                        }
                        return "<font color=\"grey\">" + qsTr("Alias") + qsTr(": ") + "</font>" + furnitureAlias
                    }
                }
                C.VFit {
                    Layout.preferredHeight: extraColumnLayout.rowHeight
                    text: {
                        var furnitureLoc = furniture["loc"]
                        if (furnitureLoc === undefined) {
                            furnitureLoc = "<font color=\"grey\">" + qsTr("Not configured") + "</font>"
                        }
                        return "<font color=\"grey\">" + qsTr("Location") + qsTr(": ") + "</font>" + furnitureLoc
                    }
                }

                ListView {
                    id: viewsListView
                    Layout.preferredWidth: extraColumnLayout.width
                    interactive: false
                    Layout.preferredHeight: contentHeight
                    model: ListModel {
                        id: viewsListModel
                    }
                    header: Component {
                        C.VFit {
                            height: viewsListView.count > 0 ? 0 : extraColumnLayout.rowHeight
                            text: "<font color=\"grey\">" + qsTr("No associated Autos") + "</font>"
                        }
                    }
                    delegate: Component {
                        C.VFit {
                            height: extraColumnLayout.rowHeight
                            text: {
                                var ret = "<font color=\"grey\">" + qsTr("Auto") + "</font>" + qsTr(": ")
                                var viewAlias = view["alias"]
                                if (viewAlias === undefined) {
                                    ret += view["uid"]
                                } else {
                                    ret += viewAlias
                                }
                                var associatedAutos = J.viewFindAssociatedAutos(view["uid"], root.autos)
                                if (associatedAutos.length === 0) {
                                    ret += "<font color=\"grey\">" + qsTr(", ") + qsTr("No arranged execution") + "</font>"
                                } else {
                                    associatedAutos.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                                    var autoStart = root.autos[associatedAutos[0]]["start"] * 1000
                                    ret += "<font color=\"grey\">" + qsTr(", ") + qsTr("Will be executed at") + qsTr(": ") + "</font>" + J.date2ShortText(new Date(autoStart))
                                }
                                return ret
                            }
                        }
                    }
                    function updateViews() {
                        var associatedViews = J.findAssociatedViews(furniture["address"], root.views)
                        var associatedViewObjs = []
                        for (var i = 0; i < associatedViews.length; ++i) {
                            associatedViewObjs.push(root.views[associatedViews[i]])
                        }
                        J.updateModelData(viewsListModel, associatedViewObjs, "view", "uid")
                    }

                    Component.onCompleted: {
                        updateViews()
                    }

                    Connections {
                        target: root
                        function onViewsChanged() {
                            viewsListView.updateViews()
                        }
                    }
                }

                RowLayout {
                    Layout.preferredWidth: extraColumnLayout.width
                    layoutDirection: Qt.RightToLeft
                    C.Rounded {
                        icon.source: "/icons/delete.svg"
                        highlighted: true
                        Material.accent: root.pink
                        onClicked: {
                            abortPopup.open()
                        }
                    }
                }
            }
            C.Popup {
                id: abortPopup
                title: qsTr("Aborting...")
                property var xhrs: []
                onOpened: {
                    var onPostJsonComplete = function(rsp) {
                        close()
                        J.removeAndNotify(root, "furnitures", "address", furniture["address"])
                    }
                    var content = {}
                    content["address"] = furniture["address"]
                    J.postJSON(settings.host + "/abort", onPostJsonComplete, root.xhrErrorHandle, content, true, xhrs)
                }
                onClosed: {
                    for (var i = 0; i < xhrs.length; ++i) {
                        xhrs[i].abort()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.commonSpacing
                    ProgressBar {
                        indeterminate: true
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
    header: Component {
        C.Touch {
            buttonHeight: 56
            buttonWidth: furnituresList.width
            onButtonClicked: {
                filterPopup.open()
            }
            enabled: furnituresList.count > 0
            buttonContentItem: Item {
                C.VFit {
                    id: filterVFit
                    height: parent.parent.height / 3
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    font.italic: true
                    text: {
                        if (furnituresList.count <= 0) {
                            return qsTr("Nothing here, and Pull to Refresh.")
                        }

                        var ret = ""
                        var entries = Object.entries(filters)
                        for (var i = 0; i < entries.length; ++i) {
                            if (i > 0) {
                                ret += qsTr(", ")
                            }
                            if (entries[i][0] === "type") {
                                ret += window.typeTexts[entries[i][1]]
                            } else {
                                ret += entries[i][1]
                            }
                        }
                        if (ret === "") {
                            ret = qsTr("No filter")
                        }
                        return ret
                    }
                }
                IconLabel {
                    height: filterVFit.height
                    width: height
                    anchors.top: filterVFit.top
                    anchors.right: parent.right
                    icon.source: "/icons/tap.svg"
                    icon.color: filterVFit.color
                    visible: furnituresList.count > 0
                }
            }
        }
    }

    C.Popup {
        id: filterPopup
        title: qsTr("Filter")
        standardButtons: Dialog.Ok | Dialog.Reset

        ColumnLayout {
            anchors.fill: parent
            spacing: root.commonSpacing

            ComboBox {
                model: {
                    var ret = root.typeTexts.concat()
                    ret.push(qsTr("Void"))
                    return ret
                }

                currentIndex: model.length - 1
                Layout.fillWidth: true
            }
            ComboBox {
                model: {
                    var ret = root.stateTexts.concat()
                    ret.push(qsTr("Void"))
                    return ret
                }
                currentIndex: model.length - 1
                Layout.fillWidth: true
            }
            TextField {
                placeholderText: qsTr("Alias")
                Layout.fillWidth: true
            }
            TextField {
                placeholderText: qsTr("Location")
                Layout.fillWidth: true
            }
        }
    }
}
