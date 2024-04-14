import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as J

C.List {
    id: viewsList
    delegate: Component {
        C.Touch {
            width: viewsList.width
            height: 87

            contentItem: Item {
                ListView {
                    id: iconsListView
                    anchors.left: parent.left
                    anchors.top: parent.top
                    height: 32
                    width: 200
                    interactive: false
                    orientation: ListView.Horizontal
                    spacing: 10
                    model: ListModel {
                        id: iconsListModel
                    }
                    Component.onCompleted: {
                        var viewStates = view["states"]
                        for (var i = 0; i < viewStates.length; ++i) {
                            iconsListModel.append({ furniture: viewStates[i] })
                        }
                    }
                    delegate: Component {
                        C.Rounded {
                            property int furnitureIndex: J.find(root.furnitures, "address", furniture["address"])
                            height: iconsListView.height
                            width: height
                            icon.source: {
                                if (furnitureIndex === -1) {
                                    return "/icons/delete.svg"
                                }
                                if (!root.furnitures[furnitureIndex]["connected"]) {
                                    return "/icons/disconnected.svg"
                                }
                                return root.typeIcons[root.furnitures[furnitureIndex]["type"]]
                            }

                            highlighted: furniture["state"] > 0 || furnitureIndex === -1 || !root.furnitures[furnitureIndex]["connected"]
                            Material.accent: furnitureIndex === -1 || !root.furnitures[furnitureIndex]["connected"] ?
                                                 "#E91E63" :
                                                 root.stateIcons[root.furnitures[furnitureIndex]["type"]][furniture["state"]]
                            ToolTip.visible: down
                            ToolTip.text: {
                                if (furnitureIndex === -1) {
                                    return qsTr("Deleted")
                                }
                                var rootFurniture = root.furnitures[furnitureIndex]
                                var furnitureAlias = rootFurniture["alias"]
                                if (furnitureAlias !== undefined) {
                                    return furnitureAlias
                                }
                                return rootFurniture["address"]
                            }
                        }
                    }
                }
                C.VFit {
                    id: viewVFit
                    anchors.left: iconsListView.left
                    anchors.top: iconsListView.bottom
                    anchors.topMargin: 10
                    anchors.right: autoVFit.left
                    anchors.rightMargin: 10
                    height: 16
                    clip: true
                    text: {
                        var viewAlias = view["alias"]
                        if (viewAlias !== undefined) {
                            return viewAlias
                        }
                        return ""
                    }
                }
                property var autoIndexes: {
                    var ret = J.findAll(root.autos, "view", view["uid"])
                    ret.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                    return ret
                }

                C.VFit {
                    id: autoVFit
                    anchors.right: parent.right
                    anchors.bottom: viewVFit.bottom
                    height: viewVFit.height
                    font.underline: true
                    enabled: parent.autoIndexes.length !== 0
                    text: {
                        if (parent.autoIndexes.length === 0) {
                            return qsTr("Failed to get the next start time.")
                        }
                        var auto = root.autos[parent.autoIndexes[0]]
                        var autoStart = auto["start"] * 1000
                        var ret = ""
                        if (autoStart !== undefined) {
                            ret += new Date(autoStart).toLocaleString()
                        }
                        return ret
                    }
                }
                RowLayout {
                    height: 32
                    anchors.verticalCenter: iconsListView.verticalCenter
                    anchors.right: parent.right
                    spacing: 10

                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: true
                        icon.source: "/icons/config.svg"
                        onClicked: {
                            configDialog.open()
                        }
                    }
                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: true
                        icon.source: parent.parent.autoIndexes.length === 0 ? "/icons/timeout.svg" : "/icons/play.svg"
                        onClicked: {
                            autoDialog.open()
                        }
                    }
                }
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
                }
                onAccepted: {
                    var onPostJsonComplete = function(rsp) {
                        var tmp = {}
                        tmp["view"] = rsp
                        viewsList.model.set(J.findModelData(viewsList.model, "view", "uid", view["uid"]), tmp)
                    }
                    var content = {}
                    content["uid"] = view["uid"]
                    content["alias"] = aliasTextField.text
                    J.postJSON(settings.host + "/view", onPostJsonComplete, root.xhrErrorHandle, content)
                }
            }
            C.Popup {
                id: autoDialog
                title: qsTr("Auto")
                standardButtons: Dialog.Ok | Dialog.Cancel
                readonly property int start: datePicker.selectedDate + timePicker.selectedTime + new Date().getTimezoneOffset() * 60
                readonly property int every: everyPicker.selectedTime
                Component.onCompleted: {
                    datePicker.reset()
                }

                ColumnLayout {
                    anchors.fill: parent
                    Label {
                        text: qsTr("Start At ")
                    }
                    Label {
                        text: new Date(autoDialog.start * 1000).toLocaleString()
                        font.underline: true
                    }
                    Label {
                        text: qsTr("Repeat Every ")
                    }
                    Label {
                        text: {
                            var day = parseInt(autoDialog.every / (24 * 60 * 60))
                            var second = autoDialog.every - day * (24 * 60 * 60)
                            var hour = parseInt(second / (60 * 60))
                            second -= hour * (60 * 60)
                            var minute = parseInt(second / 60)
                            second -= minute * 60
                            var ret = ""
                            if (day > 0) {
                                ret += day + qsTr(" Day ")
                            }
                            if (hour > 0) {
                                ret += hour + qsTr(" Hour ")
                            }
                            if (minute > 0) {
                                ret += minute + qsTr(" Minute ")
                            }
                            if (second > 0) {
                                ret += second + qsTr(" Second ")
                            }
                            if (ret === "") {
                                ret = qsTr("Not Repeated")
                            }

                            return  ret
                        }

                        font.underline: true
                    }
                    RowLayout {
                        Button {
                            text: qsTr("Set Start Date")
                            onClicked: {
                                datePickerPopup.open()
                            }
                        }
                        Button {
                            text: qsTr("Set Start Time")
                            onClicked: {
                                timePickerPopup.open()
                            }
                        }

                    }
                    Button {
                        text: qsTr("Set Interval")
                        onClicked: {
                            everyPickerPopup.open()
                        }
                    }
                }
            }
            C.Popup {
                id: datePickerPopup
                title: qsTr("Date Picker")
                standardButtons: Dialog.Ok | Dialog.Cancel
                clip: true
                contentHeight: datePickerFlickable.contentHeight
                Flickable {
                    id: datePickerFlickable
                    anchors.fill: parent
                    contentHeight: datePicker.height

                    C.DatePicker {
                        id: datePicker
                        x: (parent.width - datePicker.width) / 2
                    }
                }
            }
            C.Popup {
                id: timePickerPopup
                title: qsTr("Time Picker")
                standardButtons: Dialog.Ok | Dialog.Cancel
                C.TimePicker {
                    id: timePicker
                    x: (parent.width - width) / 2
                }
            }
            C.Popup {
                id: everyPickerPopup
                title: qsTr("Time Picker")
                standardButtons: Dialog.Ok | Dialog.Cancel
                C.TimePicker {
                    id: everyPicker
                    x: (parent.width - width) / 2
                    daySpinBoxVisible: true
                }
            }
        }
    }
}
// onAccepted: {
//     var onPostJsonComplete = function(rsp) {
//         var tmp = {}
//         tmp["view"] = rsp
//         viewsList.model.set(J.findModelData(viewsList.model, "view", "uid", view["uid"]), tmp)
//     }
//     var content = {}
//     content["view"] = view["uid"]
//     if (startTextField.text !== "") {
//         content["start"] = Number(startTextField.text)
//     }
//     if (everyTextField.text !== "") {
//         content["every"] = Number(everyTextField.text)
//     }

//     J.postJSON(settings.host + "/view", onPostJsonComplete, root.xhrErrorHandle, content)
// }
