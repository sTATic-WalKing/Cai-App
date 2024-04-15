﻿import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as J

C.List {
    id: furnituresList
    property var filters: ({})

    delegate: Component {
        C.Touch {
            width: furnituresList.width
            height: 60

            contentItem: Item {
                C.Rounded {
                    id: iconLabel
                    height: 32
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    icon.source: root.typeIcons[furniture["type"]]
                    highlighted: furniture["state"] !== undefined && furniture["state"] > 0
                    Material.accent: furniture["state"] !== undefined ? root.stateIcons[furniture["type"]][furniture["state"]] : root.stateIcons[furniture["type"]][0]
                    enabled: furniture["state"] !== undefined

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
                    id: displayLabel
                    height: 15
                    anchors.top: iconLabel.verticalCenter
                    anchors.left: iconLabel.right
                    anchors.leftMargin: 10
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
                    height: 12
                    anchors.left: displayLabel.left
                    anchors.bottom: displayLabel.top
                    property bool associated
                    text: {
                        var associatedViews = []
                        for (var i = 0; i < root.views.length; ++i) {
                            var view = root.views[i]
                            if (J.find(view["states"], "address", furniture["address"]) !== -1) {
                                associatedViews.push(view)
                            }
                        }
                        var associatedAutoIndexes = []
                        for (i = 0; i < associatedViews.length; ++i) {
                            associatedAutoIndexes = associatedAutoIndexes.concat(J.findAll(root.autos, "view", associatedViews[i]["uid"]))
                        }
                        associatedAutoIndexes.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                        if (associatedAutoIndexes.length > 0) {
                            var auto = root.autos[associatedAutoIndexes[0]]
                            var states = root.views[J.find(root.views, "uid", auto["view"])]["states"]
                            associated = true
                            return qsTr("Will be") + " <u>" + root.stateTexts[states[J.find(states, "address", furniture["address"])]["state"]] + "</u> " + qsTr("at") + " <u>" + new Date(auto["start"] * 1000).toLocaleString() + "</u>"
                        }

                        return qsTr("No Associated Autos")
                    }

                    enabled: associated
                }

                RowLayout {
                    height: iconLabel.height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: 10

                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: furniture["connected"]
                        enabled: furniture["connected"]
                        icon.source: "/icons/config.svg"

                        onClicked: {
                            configDialog.open()
                        }
                    }
                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: true
                        icon.source: furniture["connected"] ? "/icons/connected.svg" : "/icons/disconnected.svg"
                        Material.accent: furniture["connected"] ? parent.Material.accent : "#E91E63"
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
                id: configDialog
                title: qsTr("Config")
                standardButtons: Dialog.Ok | Dialog.Cancel
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

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
                    content["alias"] = aliasTextField.text
                    content["loc"] = locTextField.text
                    J.postJSON(settings.host + "/config", onPostJsonComplete, root.xhrErrorHandle, content)
                }
            }
        }
    }
    header: Component {
        C.Touch {
            height: 56
            width: furnituresList.width
            onClicked: {
                filterDialog.open()
            }
            enabled: furnituresList.count > 0

            contentItem: Item {
                C.VFit {
                    id: filterLabel
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
                    height: filterLabel.height
                    width: height
                    anchors.top: filterLabel.top
                    anchors.right: parent.right
                    icon.source: "/icons/tap.svg"
                    icon.color: filterLabel.color
                    visible: furnituresList.count > 0
                }
            }
        }
    }

    C.Popup {
        id: filterDialog
        title: qsTr("Filter")
        standardButtons: Dialog.Ok | Dialog.Reset

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

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
