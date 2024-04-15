import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as J

C.List {
    id: viewsList
    delegate: Component {
        C.Touch {
            id: viewsListTouch
            width: viewsList.width
            height: 87
            property var autoIndexes: {
                var ret = J.findAll(root.autos, "view", view["uid"])
                ret.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                return ret
            }
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
                        C.RoundedFurniture {
                            height: iconsListView.height
                            width: height
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
                        return view["uid"]
                    }
                }

                C.VFit {
                    id: autoVFit
                    anchors.right: parent.right
                    anchors.bottom: viewVFit.bottom
                    height: viewVFit.height
                    font.underline: true
                    enabled: viewsListTouch.autoIndexes.length !== 0
                    text: {
                        if (viewsListTouch.autoIndexes.length === 0) {
                            return qsTr("Failed to get the next start time.")
                        }
                        var auto = root.autos[viewsListTouch.autoIndexes[0]]
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
                        icon.source: viewsListTouch.autoIndexes.length === 0 ? "/icons/timeout.svg" : "/icons/play.svg"
                        onClicked: {
                            if (viewsListTouch.autoIndexes.length === 0) {
                                autoDialog.open()
                            } else {
                                autoAbortDialog.open()
                            }

                        }
                    }
                }
            }
            function updateTimer() {
                viewsListTimer.stop()
                if (viewsListTouch.autoIndexes.length === 0) {
                    return
                }
                viewsListTimer.auto = root.autos[viewsListTouch.autoIndexes[0]]
                viewsListTimer.interval = Math.max((viewsListTimer.auto["start"] + 1) * 1000 - root.currentDate.getTime(), 0)
                viewsListTimer.start()
            }

            onAutoIndexesChanged: {
                updateTimer()
            }
            Timer {
                id: viewsListTimer
                property var auto
                onTriggered: {
                    if (auto["every"] !== undefined) {
                        var onPostJsonComplete = function(rsp) {
                            J.updateAndNotify(root, "autos", "uid", rsp)
                        }
                        var onError = function(xhr) {
                            if (xhr.status === 404) {
                                J.removeAndNotify(root, "autos", "uid", auto["uid"])
                            } else {
                                root.xhrErrorHandle(xhr)
                            }
                        }
                        J.postJSON(settings.host + "/auto", onPostJsonComplete, onError, { "uid": auto["uid"] })
                    } else {
                        J.removeAndNotify(root, "autos", "uid", auto["uid"])
                    }
                    var states = view["states"]
                    for (var i = 0; i < states.length; ++i) {
                        var local_i = i
                        var onInnerPostJsonComplete = function(rsp) {
                            var index = J.find(root.furnitures, "address", states[local_i]["address"])
                            if (index === -1) {
                                return
                            }
                            var data = root.furnitures[index]
                            data["state"] = rsp["state"]
                            J.updateAndNotify(root, "furnitures", "address", data)
                        }
                        var content = {}
                        content["address"] = states[i]["address"]
                        J.postJSON(settings.host + "/state", onInnerPostJsonComplete, root.xhrErrorHandle, content)
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
                readonly property int start: datePicker.selectedDate + timePicker.selectedTime + root.currentDate.getTimezoneOffset() * 60
                readonly property int every: everyPicker.selectedTime
                onAboutToShow: {
                    datePicker.reset()
                    timePicker.reset()
                }
                onAccepted: {
                    var onPostJsonComplete = function(rsp) {
                        J.updateAndNotify(root, "autos", "uid", rsp)
                    }
                    var content = {}
                    content["view"] = view["uid"]
                    if (autoDialog.start * 1000 > root.currentDate.getTime()) {
                        content["start"] = autoDialog.start
                    }
                    if (autoDialog.every > 0) {
                        content["every"] = autoDialog.every
                    }

                    J.postJSON(settings.host + "/auto", onPostJsonComplete, root.xhrErrorHandle, content)
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        text: qsTr("Start At")
                    }
                    Label {
                        text: {
                            var start = autoDialog.start * 1000
                            if (start <= root.currentDate.getTime()) {
                                return qsTr("Now")
                            }
                            return new Date(start).toLocaleString()
                        }

                        font.underline: true
                    }
                    Label {
                        text: qsTr("Repeat Every")
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
                                ret += day + " " + qsTr("Day") + " "
                            }
                            if (hour > 0) {
                                ret += hour + " " + qsTr("Hour") + " "
                            }
                            if (minute > 0) {
                                ret += minute + " " + qsTr("Minute") + " "
                            }
                            if (second > 0) {
                                ret += second + " " + qsTr("Second") + " "
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
            C.Popup {
                id: autoAbortDialog
                title: qsTr("Abort Autos")
                standardButtons: Dialog.Ok | Dialog.Cancel
                onAccepted: {
                    var uids = []
                    for (var i = 0; i < viewsListTouch.autoIndexes.length; ++i) {
                        uids.push(root.autos[viewsListTouch.autoIndexes[i]]["uid"])
                    }

                    for (i = 0; i < uids.length; ++i) {
                        var local_i = i
                        var onPostJsonComplete = function(rsp) {
                            if (rsp["affected"] > 0) {
                                J.removeAndNotify(root, "autos", "uid", uids[local_i])
                            }
                        }
                        var content = {}
                        content["uid"] = uids[i]
                        J.postJSON(settings.host + "/abort", onPostJsonComplete, root.xhrErrorHandle, content)
                    }
                }
                Label {
                    text: qsTr("Abort all associated autos, are you sure?")
                }
            }
        }
    }
    header: Component {
        C.Touch {
            height: 56
            width: viewsList.width

            onClicked: {
                addDialog.open()
            }

            contentItem: Item {
                C.VFit {
                    id: filterLabel
                    height: parent.parent.height / 3
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    font.italic: true
                    text: qsTr("Add a new View")
                }
                IconLabel {
                    height: filterLabel.height
                    width: height
                    anchors.top: filterLabel.top
                    anchors.right: parent.right
                    icon.source: "/icons/addto.svg"
                    icon.color: filterLabel.color
                }
            }

            C.Popup {
                id: addDialog
                title: qsTr("Add a View")
                standardButtons: Dialog.Ok | Dialog.Cancel
                clip: true
                contentHeight: addFlickable.contentHeight
                onAccepted: {
                    if (addListModel.count <= 0) {
                        return
                    }

                    var onPostJsonComplete = function(rsp) {
                        var tmp = {}
                        tmp["view"] = rsp
                        viewsList.model.append(tmp)
                    }
                    var content = {}
                    content["alias"] = aliasTextField.text
                    var states = []
                    for (var i = 0; i < addListModel.count; ++i) {
                        states.push(addListModel.get(i)["furniture"])
                    }
                    content["states"] = states
                    J.postJSON(settings.host + "/view", onPostJsonComplete, root.xhrErrorHandle, content)
                }
                onAboutToShow: {
                    addListModel.clear()
                }

                Flickable {
                    id: addFlickable
                    anchors.fill: parent
                    contentHeight: addColumnLayout.height
                    ColumnLayout {
                        id: addColumnLayout
                        spacing: 10
                        anchors.left: parent.left
                        anchors.right: parent.right

                        TextField {
                            id: aliasTextField
                            placeholderText: qsTr("Alias")
                            Layout.fillWidth: true
                        }
                        Button {
                            icon.source: "/icons/addto.svg"
                            text: qsTr("Associate")

                            onClicked: {
                                associatePopup.open()
                            }
                        }
                        GridView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: contentHeight
                            interactive: false
                            cellHeight: 42
                            cellWidth: cellHeight

                            model: ListModel {
                                id: addListModel
                            }
                            delegate: Component {
                                C.RoundedFurniture {
                                    height: 32
                                    width: height
                                }
                            }
                        }
                    }
                }

                C.Popup {
                    id: associatePopup
                    title: qsTr("Associate")
                    standardButtons: Dialog.Ok | Dialog.Cancel
                    onAboutToShow: {
                        var added = []
                        for (var i = 0; i < addListModel.count; ++i) {
                            added.push(addListModel.get(i)["furniture"]["address"])
                        }
                        var all = []
                        for (i = 0; i < root.furnitures.length; ++i) {
                            all.push(root.furnitures[i]["address"])
                        }
                        var toAdd = J.difference(all, added)
                        var res = []
                        for (i = 0; i < toAdd.length; ++i) {
                            var furniture = root.furnitures[J.find(root.furnitures, "address", toAdd[i])]
                            var tmp = {}
                            tmp["address"] = furniture["address"]
                            var furnitureAlias = furniture["alias"]
                            if (furnitureAlias === undefined) {
                                tmp["alias"] = furniture["address"]
                            } else {
                                tmp["alias"] = furniture["alias"]
                            }
                            res.push(tmp)
                        }
                        associateFurnitureComboBox.model = res
                    }
                    onAccepted: {
                        addListModel.append({"furniture": { "address": associateFurnitureComboBox.currentValue, "state": associateStateComboBox.currentIndex }})
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        ComboBox {
                            id: associateFurnitureComboBox
                            Layout.fillWidth: true
                            textRole: "alias"
                            valueRole: "address"
                        }

                        ComboBox {
                            id: associateStateComboBox
                            model: root.stateTexts
                            Layout.fillWidth: true
                        }
                    }

                }
            }
        }
    }
}
