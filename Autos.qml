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
                var ret = J.viewFindAssociatedAutos(view["uid"], root.autos)
                ret.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                return ret
            }
            buttonContentItem: Item {
                ListView {
                    id: iconsListView
                    anchors.left: parent.left
                    anchors.top: parent.top
                    height: root.roundedSize
                    width: 200
                    interactive: false
                    orientation: ListView.Horizontal
                    spacing: root.commonSpacing
                    model: ListModel {
                        id: iconsListModel
                    }
                    Component.onCompleted: {
                        var viewStates = view["states"]
                        J.updateModelData(iconsListModel, viewStates, "furniture", "address")
                    }
                    delegate: Component {
                        C.RoundedFurniture { }
                    }
                }
                C.VFit {
                    id: viewVFit
                    anchors.left: iconsListView.left
                    anchors.top: iconsListView.bottom
                    anchors.topMargin: root.commonSpacing
                    anchors.right: autoVFit.left
                    anchors.rightMargin: root.commonSpacing
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
                    enabled: viewsListTouch.autoIndexes.length !== 0
                    text: {
                        if (viewsListTouch.autoIndexes.length > 0) {
                            var autoStart = root.autos[viewsListTouch.autoIndexes[0]]["start"] * 1000
                            return "<font color=\"grey\">" + qsTr("Will be executed at ") + "</font>" + J.date2ShortText(new Date(autoStart))
                        }

                        return "<font color=\"grey\">" + qsTr("No arranged execution") + "</font>"
                    }
                }
                RowLayout {
                    height: 32
                    anchors.verticalCenter: iconsListView.verticalCenter
                    anchors.right: parent.right
                    spacing: root.commonSpacing
                    layoutDirection: Qt.RightToLeft
                    C.Rounded {
                        highlighted: true
                        icon.source: viewsListTouch.autoIndexes.length === 0 ? "/icons/timeout.svg" : "/icons/play.svg"
                        onClicked: {
                            if (viewsListTouch.autoIndexes.length === 0) {
                                autoCreatePopup.open()
                            } else {
                                autosAbortPopup.open()
                            }

                        }
                    }
                    C.Rounded {
                        highlighted: true
                        icon.source: "/icons/config.svg"
                        onClicked: {
                            configPopup.open()
                        }
                    }

                }
            }
            function updateTimer() {
                autosTimer.stop()
                if (viewsListTouch.autoIndexes.length === 0) {
                    return
                }
                autosTimer.auto = root.autos[viewsListTouch.autoIndexes[0]]
                autosTimer.interval = Math.max((autosTimer.auto["start"] + 1) * 1000 - new Date().getTime(), 1000)
                autosTimer.start()
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
                id: autosTimer
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
                        var onInnerPostJsonComplete = function(rsp) {
                            J.updateAndNotify(root, "furnitures", "address", rsp)
                        }
                        J.postJSON(settings.host + "/config", onInnerPostJsonComplete, root.xhrErrorHandle, { "address": states[i]["address"] })
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
                }
                onAccepted: {
                    if (aliasTextField.text === "") {
                        root.toolBarShowToolTip(qsTr("Inputs cannot all be empty! "))
                        return
                    }

                    var onPostJsonComplete = function(rsp) {
                        J.updateAndNotify(root, "views", "uid", rsp)
                    }
                    var content = {}
                    content["uid"] = view["uid"]
                    content["alias"] = aliasTextField.text
                    J.postJSON(settings.host + "/view", onPostJsonComplete, root.xhrErrorHandle, content)
                }
            }
            C.Popup {
                id: autoCreatePopup
                title: qsTr("Auto")
                standardButtons: Dialog.Ok
                readonly property int start: datePicker.selectedDate + timePicker.selectedTime + new Date().getTimezoneOffset() * 60
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
                    if (autoCreatePopup.start * 1000 > new Date().getTime()) {
                        content["start"] = autoCreatePopup.start
                    }
                    if (autoCreatePopup.every > 0) {
                        content["every"] = autoCreatePopup.every
                    }

                    J.postJSON(settings.host + "/auto", onPostJsonComplete, root.xhrErrorHandle, content)
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.commonSpacing
                    Label {
                        text: {
                            var ret = "<font color=\"grey\">" + qsTr("Start") + qsTr(": ") + "</font>"
                            var start = autoCreatePopup.start * 1000
                            if (start <= new Date().getTime()) {
                                ret += qsTr("Now")
                            } else {
                                ret += new Date(start).toLocaleString()
                            }
                            return ret
                        }
                    }
                    Label {
                        text: {
                            var ret = "<font color=\"grey\">" + qsTr("Interval") + qsTr(": ") + "</font>"
                            if (autoCreatePopup.every === 0) {
                                ret += qsTr("Not Repeated")
                            } else {
                                ret += J.stamp2SpanText(autoCreatePopup.every, root.unitsOfTime)
                            }
                            return ret
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.commonSpacing

                        C.Rounded {
                            highlighted: true
                            icon.source: "/icons/date.svg"
                            onClicked: {
                                datePickerPopup.open()
                            }
                        }
                        C.Rounded {
                            highlighted: true
                            icon.source: "/icons/watch.svg"
                            onClicked: {
                                timePickerPopup.open()
                            }
                        }
                        C.Rounded {
                            highlighted: true
                            icon.source: "/icons/interval.svg"
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
                id: autosAbortPopup
                title: qsTr("Stop Autos")
                standardButtons: Dialog.Ok
                onAccepted: {
                    viewsListTouch.abortAutos()
                }
                ColumnLayout {
                    anchors.fill: parent
                    spacing: root.commonSpacing
                    Label {
                        text: qsTr("Stop all arranged execution, are you sure?")
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
                            viewAlias = "<font color=\"grey\">" + qsTr("Not configured") + "</font>"
                        }
                        return "<font color=\"grey\">" + qsTr("Alias") + qsTr(": ") + "</font>" + viewAlias
                    }
                }
                ListView {
                    id: autosListView
                    Layout.preferredWidth: extraColumnLayout.width
                    interactive: false
                    model: ListModel {
                        id: autosListModel
                    }
                    Layout.preferredHeight: contentHeight
                    function updateAutos() {
                        var autos = []
                        for (var i = 0; i < viewsListTouch.autoIndexes.length; ++i) {
                            autos.push(root.autos[viewsListTouch.autoIndexes[i]])
                        }
                        J.updateModelData(autosListModel, autos, "auto", "uid")
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
                            height: autosListView.count > 0 ? 0 : extraColumnLayout.rowHeight
                            text: "<font color=\"grey\">" + qsTr("No arranged execution") + "</font>"
                        }
                    }
                    delegate: Component {
                        C.VFit {
                            height: extraColumnLayout.rowHeight
                            text: {
                                var ret = "<font color=\"grey\">" + qsTr("Start") + qsTr(": ") + "</font>" + new Date(auto["start"] * 1000).toLocaleString()
                                var every = auto["every"]
                                if (every !== undefined) {
                                    ret += "<font color=\"grey\">" + qsTr(", ") + qsTr("Interval") + qsTr(": ") +  "</font>" + J.stamp2SpanText(every, root.unitsOfTime)
                                }
                                return ret
                            }
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
                            viewAbortPopup.open()
                        }
                    }
                }
            }
            C.Popup {
                id: viewAbortPopup
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
            buttonWidth: viewsList.width
            onButtonClicked: {
                viewCreatePopup.open()
            }
            buttonContentItem: Item {
                C.VFit {
                    id: createLabel
                    height: parent.parent.height / 3
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    font.italic: true
                    text: qsTr("Create an Auto")
                }
                IconLabel {
                    height: createLabel.height
                    width: height
                    anchors.top: createLabel.top
                    anchors.right: parent.right
                    icon.source: "/icons/addto.svg"
                    icon.color: createLabel.color
                }
            }

            C.Popup {
                id: viewCreatePopup
                title: qsTr("Create an Auto")
                standardButtons: Dialog.Ok
                clip: true
                contentHeight: createFlickable.contentHeight
                onAccepted: {
                    if (createListModel.count <= 0) {
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
                    for (var i = 0; i < createListModel.count; ++i) {
                        states.push(createListModel.get(i)["furniture"])
                    }
                    content["states"] = states
                    J.postJSON(settings.host + "/view", onPostJsonComplete, root.xhrErrorHandle, content)
                }
                onAboutToShow: {
                    createListModel.clear()
                }

                Flickable {
                    id: createFlickable
                    anchors.fill: parent
                    contentHeight: createColumnLayout.height
                    ColumnLayout {
                        id: createColumnLayout
                        spacing: root.commonSpacing
                        anchors.left: parent.left
                        anchors.right: parent.right

                        TextField {
                            id: aliasTextField
                            placeholderText: qsTr("Alias")
                            Layout.fillWidth: true
                        }
                        C.Rounded {
                            highlighted: true
                            icon.source: "/icons/addto.svg"

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
                                id: createListModel
                            }
                            delegate: Component {
                                C.RoundedFurniture { }
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
                        for (var i = 0; i < createListModel.count; ++i) {
                            added.push(createListModel.get(i)["furniture"]["address"])
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

                        createListModel.append({"furniture": { "address": associateFurnitureComboBox.currentValue, "state": associateStateComboBox.currentIndex }})
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: root.commonSpacing
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
