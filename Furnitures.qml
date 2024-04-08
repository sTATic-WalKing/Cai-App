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
    Component.onCompleted: {
        Common.updateModelData(listModel, furnitures, "furniture", "address")
    }

    function onDownloadConfigsComplete(list) {
        furnitures = list
        Common.updateModelData(listModel, furnitures, "furniture", "address")
    }
    function downloadConfigs(list) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if(xhr.readyState !== 4) {
                return
            }
            if (xhr.status !== 200) {
                root.xhrErrorHandle(xhr)
                return
            }
            console.log(xhr.responseURL, xhr.responseText.toString())
            var addresses = JSON.parse(xhr.responseText.toString())["addresses"]
            for (var i = 0; i < list.length; ++i) {
                list[i]["connected"] = addresses.indexOf(list[i]["address"]) !== -1
            }
            for (i = 0; i < addresses.length; ++i) {
                xhr = new XMLHttpRequest()
                var local_i = i
                xhr.onreadystatechange = function() {
                    if(xhr.readyState !== 4) {
                        return
                    }
                    if (xhr.status !== 200) {
                        root.xhrErrorHandle(xhr)
                    } else {
                        console.log(xhr.responseURL, xhr.responseText.toString())
                        list[Common.find(list, "address", addresses[local_i])]["state"] = JSON.parse(xhr.responseText.toString())["state"]
                    }
                    if (addresses.length - 1 === local_i) {
                        onDownloadConfigsComplete(list)
                    }
                }
                xhr.open("POST", "http://192.168.29.176:11151" + "/state");
                xhr.send(JSON.stringify({ address: list[i]["address"] }));
            }
        }
        xhr.open("POST", "http://192.168.29.176:11151" + "/addresses");
        xhr.send(JSON.stringify({}));
    }
    onRefresh: {
        console.log("refresh")
        Common.downloadModelData("http://192.168.29.176:11151", "config", "address", downloadConfigs, root.xhrErrorHandle)
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
                }
                Label {
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
                    }
                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: furniture["connected"]
                        icon.source: furniture["connected"] ? "/icons/connect.svg" : "/icons/disconnect.svg"
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
        }
    }

    Dialog {
        id: filterDialog
        anchors.centerIn: parent
        parent: Overlay.overlay
        focus: true
        modal: true
        title: qsTr("Filter")
        standardButtons: Dialog.Ok | Dialog.Reset
        width: parent.width
        Material.roundedScale: Material.NotRounded

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            ComboBox {
                model: [ qsTr("Light"), qsTr("Void") ]
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
