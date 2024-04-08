import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as Common

C.List {
    id: furnituresList
    required property var furnitures
    required property var autos
    property var filters: ({})
    delegate: delegateComponent
    header: headerComponent
    model: ListModel {
        id: listModel
    }

    function onDownloadConfigsComplete(list) {
        furnitures = list
        Common.updateModelData(listModel, furnitures, "furniture", "address")
    }
    function downloadConfigs(list) {
        for (var i = 0; i < list.length; ++i) {
            var current = list[i]
            if (!current["connected"]) {
                continue
            }
            var onInnerPostJsonComplete = function(rsp) {
                list[Common.find(list, "address", current["address"])]["state"] = rsp["state"]
            }
            Common.postJSON(settings.host + "/state", { address: current["address"] }, false, onInnerPostJsonComplete, root.xhrErrorHandle)
        }
        onDownloadConfigsComplete(list)
    }
    onRefresh: {
        console.log("refresh")
        Common.downloadModelData(settings.host, "config", "address", downloadConfigs, root.xhrErrorHandle)
    }

    Component {
        id: headerComponent
        C.Touch {
            height: 56
            width: furnituresList.width
            onClicked: {
                filterDialog.open()
            }

            contentItem: Item {
                Label {
                    id: filterLabel
                    height: parent.parent.height / 3
                    anchors.verticalCenter: parent.verticalCenter
                    fontSizeMode: Text.VerticalFit
                    minimumPixelSize: 10
                    font.pixelSize: 72
                    anchors.left: parent.left
                    font.italic: true
                    text: {
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
                }
            }
        }
    }

    Component {
        id: delegateComponent
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
                    highlighted: furniture["state"] > 0
                    Material.accent: root.stateIcons[furniture["type"]][furniture["state"]]

                    onClicked: {
                        var onPostJsonComplete = function(rsp) {
                            var obj = furnitures[Common.find(furnitures, "address", furniture["address"])]
                            obj["state"] = rsp["state"]
                            var tmp = {}
                            tmp["furniture"] = obj
                            listModel.set(Common.findModelData(listModel, "furniture", "address", furniture["address"]), tmp)
                        }
                        var content = {}
                        content["state"] = furniture["state"] > 0 ? 0 : 1
                        content["address"] = furniture["address"]
                        Common.postJSON(settings.host + "/state", content, true, onPostJsonComplete, root.xhrErrorHandle)
                    }
                }
                Label {
                    id: displayLabel
                    height: 15
                    width: contentWidth
                    anchors.top: iconLabel.verticalCenter
                    fontSizeMode: Text.VerticalFit
                    minimumPixelSize: 10
                    font.pixelSize: 72
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
                Label {
                    height: 12
                    anchors.left: displayLabel.left
                    anchors.bottom: displayLabel.top
                    width: contentWidth
                    fontSizeMode: Text.VerticalFit
                    minimumPixelSize: 10
                    font.pixelSize: 72
                    text: qsTr("No Associated Autos")
                    color: "#aaaaaa"
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
                        highlighted: furniture["connected"]
                        icon.source: furniture["connected"] ? "/icons/connected.svg" : "/icons/disconnected.svg"
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
                        rsp["state"] = furniture["state"]
                        var tmp = {}
                        tmp["furniture"] = rsp
                        listModel.set(Common.findModelData(listModel, "furniture", "address", furniture["address"]), tmp)
                    }
                    var content = {}
                    content["address"] = furniture["address"]
                    content["alias"] = aliasTextField.text
                    content["loc"] = locTextField.text
                    Common.postJSON(settings.host + "/config", content, true, onPostJsonComplete, root.xhrErrorHandle)
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

    C.Popup {
        id: refreshPopup
        title: qsTr("刷新")

        ColumnLayout {
            id: refreshColumnLayout
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
}
