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
            buttonWidth: viewsList.width
            buttonHeight: 87
            property var autoIndexes: {
                var ret = J.findAll(root.autos, "view", view["uid"])
                ret.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                return ret
            }
            buttonContentItem: Item {
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
                    font.underline: viewsListTouch.autoIndexes.length !== 0
                    enabled: viewsListTouch.autoIndexes.length !== 0
                    text: {
                        if (viewsListTouch.autoIndexes.length > 0) {
                            var autoStart = root.autos[viewsListTouch.autoIndexes[0]]["start"] * 1000
                            return J.date2ShortText(new Date(autoStart), root.currentDate)
                        }

                        return qsTr("Failed to get the next start time.")
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
                            configPopup.open()
                        }
                    }
                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: true
                        icon.source: viewsListTouch.autoIndexes.length === 0 ? "/icons/timeout.svg" : "/icons/play.svg"
                        onClicked: {
                            if (viewsListTouch.autoIndexes.length === 0) {
                                autoPopup.open()
                            } else {
                                autoAbortPopup.open()
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
                viewsListTimer.interval = Math.max((viewsListTimer.auto["start"] + 1) * 1000 - root.currentDate.getTime(), 1000)
                viewsListTimer.start()
            }
            function abortAutos(onComplete=undefined, xhrs=[]) {
                var uids = []
                for (var i = 0; i < viewsListTouch.autoIndexes.length; ++i) {
                    uids.push(root.autos[viewsListTouch.autoIndexes[i]]["uid"])
                }
                if (uids.length === 0 && onComplete !== undefined) {
                    onComplete()
                }

                for (i = 0; i < uids.length; ++i) {
                    var local_i = i
                    var onPostJsonComplete = function(rsp) {
                        J.removeAndNotify(root, "autos", "uid", uids[local_i])
                        if (onComplete !== undefined && local_i === uids.length - 1) {
                            onComplete()
                        }
                    }
                    var content = {}
                    content["uid"] = uids[i]
                    J.postJSON(settings.host + "/abort", onPostJsonComplete, root.xhrErrorHandle, content, true, xhrs)
                }
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
                id: configPopup
                title: qsTr("Config")
                standardButtons: Dialog.Ok
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
                    if (aliasTextField.text === "") {
                        root.toolBarShowToolTip(qsTr("Inputs cannot all be empty! "))
                        return
                    }

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
                id: autoPopup
                title: qsTr("Auto")
                standardButtons: Dialog.Ok
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
                    if (autoPopup.start * 1000 > root.currentDate.getTime()) {
                        content["start"] = autoPopup.start
                    }
                    if (autoPopup.every > 0) {
                        content["every"] = autoPopup.every
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
                            var start = autoPopup.start * 1000
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
                            var ret = J.stamp2SpanText(autoPopup.every, root.unitOfTime)
                            if (ret === "") {
                                ret = qsTr("Not Repeated")
                            }
                            return  ret
                        }

                        font.underline: true
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            highlighted: true
                            text: qsTr("Set Start Date")
                            onClicked: {
                                datePickerPopup.open()
                            }
                        }
                        Button {
                            highlighted: true
                            text: qsTr("Set Start Time")
                            onClicked: {
                                timePickerPopup.open()
                            }
                        }
                        Button {
                            highlighted: true
                            text: qsTr("Set Interval")
                            onClicked: {
                                everyPickerPopup.open()
                            }
                        }
                    }
                }
            }
            C.Popup {
                id: datePickerPopup
                title: qsTr("Date Picker")
                standardButtons: Dialog.Ok
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
                standardButtons: Dialog.Ok
                C.TimePicker {
                    id: timePicker
                    x: (parent.width - width) / 2
                }
            }
            C.Popup {
                id: everyPickerPopup
                title: qsTr("Interval Picker")
                standardButtons: Dialog.Ok
                C.TimePicker {
                    id: everyPicker
                    x: (parent.width - width) / 2
                    daySpinBoxVisible: true
                }
            }
            C.Popup {
                id: autoAbortPopup
                title: qsTr("Abort Autos")
                standardButtons: Dialog.Ok
                onAccepted: {
                    viewsListTouch.abortAutos()
                }
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        text: qsTr("Abort all associated autos, are you sure?")
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
                x: buttonContentItem.x
                width: buttonContentItem.width
                clip: true

                readonly property real rowHeight: 15
                C.VFit {
                    Layout.preferredHeight: extraColumnLayout.rowHeight
                    text: "<font color=\"grey\">" + qsTr("UID") + qsTr(": ") + "</font>" + view["uid"]
                }
                C.VFit {
                    Layout.preferredHeight: extraColumnLayout.rowHeight
                    text: {
                        var viewAlias = view["alias"]
                        if (viewAlias === undefined) {
                            viewAlias = "<i>" + qsTr("Not configured") + "</i>"
                        }
                        return "<font color=\"grey\">" + qsTr("Alias") + qsTr(": ") + "</font>" + viewAlias
                    }
                }
                ListView {
                    id: autosListView
                    Layout.preferredWidth: extraColumnLayout.width
                    interactive: false
                    spacing: extraColumnLayout.spacing
                    model: ListModel {
                        id: autosListModel
                    }
                    Layout.preferredHeight: contentHeight
                    function updateAutos() {
                        autosListModel.clear()
                        for (var i = 0; i < viewsListTouch.autoIndexes.length; ++i) {
                            autosListModel.append({ "auto": root.autos[viewsListTouch.autoIndexes[i]] })
                        }
                    }
                    Component.onCompleted: {
                        updateAutos()
                    }
                    Connections {
                        target: viewsListTouch
                        function onAutoIndexesChanged() {
                            autosListView.updateAutos()
                        }
                    }

                    header: Component {
                        C.VFit {
                            height: extraColumnLayout.rowHeight
                            text: "<font color=\"grey\">" + qsTr("Autos") + qsTr(": ") + "</font>" + (autosListView.count > 0 ? "" : qsTr("No associated Autos"))
                        }
                    }
                    delegate: Component {
                        C.VFit {
                            height: extraColumnLayout.rowHeight
                            text: {
                                var ret = qsTr("UID") + qsTr(": ") + auto["uid"] + qsTr(", ") +
                                          qsTr("Start") + qsTr(": ") + new Date(auto["start"] * 1000).toLocaleString()
                                var every = auto["every"]
                                if (every !== undefined) {
                                    ret += qsTr(", ") + qsTr("Interval") + qsTr(": ") + J.stamp2SpanText(every, root.unitOfTime)
                                }
                                return ret

                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredWidth: extraColumnLayout.width
                    Button {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 48
                        flat: true
                        Material.roundedScale: Material.NotRounded
                        topInset: 0
                        bottomInset: 0
                        leftInset: 0
                        rightInset: 0
                        onClicked: {
                            abortViewPopup.open()
                        }

                        C.VFit {
                            anchors.centerIn: parent
                            height: extraColumnLayout.rowHeight
                            text: qsTr("ABORT")
                            color: root.warnColor
                        }
                    }
                }
            }
            C.Popup {
                id: abortViewPopup
                title: qsTr("Aborting...")
                property var xhrs: []
                onOpened: {
                    var onAbortAutosComplete = function() {
                        var onPostJsonComplete = function(rsp) {
                            close()
                            J.removeAndNotify(root, "views", "uid", view["uid"])
                        }
                        var content = {}
                        content["uid"] = view["uid"]
                        J.postJSON(settings.host + "/abort", onPostJsonComplete, root.xhrErrorHandle, content, true, xhrs)
                    }
                    viewsListTouch.abortAutos(onAbortAutosComplete, xhrs)
                }
                onClosed: {
                    for (var i = 0; i < xhrs.length; ++i) {
                        xhrs[i].abort()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
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
            buttonWidth: viewsList.width

            onButtonClicked: {
                addPopup.open()
            }

            buttonContentItem: Item {
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
                id: addPopup
                title: qsTr("Add a View")
                standardButtons: Dialog.Ok
                clip: true
                contentHeight: addFlickable.contentHeight
                onAccepted: {
                    if (addListModel.count <= 0) {
                        root.toolBarShowToolTip(qsTr("No associated Furnitures! "))
                        return
                    }

                    var onPostJsonComplete = function(rsp) {
                        J.updateAndNotify(root, "views", "uid", rsp)
                    }
                    var content = {}
                    if (aliasTextField.text !== "") {
                        content["alias"] = aliasTextField.text
                    }
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
                            highlighted: true
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
                    standardButtons: Dialog.Ok
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
                        if (associateFurnitureComboBox.currentValue === undefined) {
                            root.toolBarShowToolTip(qsTr("No selected Furnitures! "))
                            return
                        }

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
