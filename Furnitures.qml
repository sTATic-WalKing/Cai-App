import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: flickable

    required property color foreground
    required property var furnitures
    property var filters: ({})

    function onEnter(){
    }

    contentHeight: listView.height
    ListView {
        id: listView
        width: flickable.width
        height: flickable.height
        delegate: delegateComponent
        header: headerComponent
        headerPositioning: ListView.PullBackHeader

        model: ListModel {
            // Component.onCompleted: {
            //     append({ "config": { "connected": true, "address": "sssss", "type": 0 } })
            //     append({ "config": { "connected": false, "address": "dfasfadfafdf", "type": 0, "alias": "新买的台灯", "loc": "大房间" } })
            // }
        }

        Component {
            id: headerComponent
            Button {
                id: filterButton
                height: 56
                width: listView.width
                flat: true
                topInset: 0
                bottomInset: 0
                Material.roundedScale: Material.NotRounded
                onClicked: {
                    filterDialog.open()
                }

                Label {
                    id: filterLabel
                    height: parent.height / 3
                    anchors.verticalCenter: parent.verticalCenter
                    fontSizeMode: Text.VerticalFit
                    minimumPixelSize: 10
                    font.pixelSize: 72
                    anchors.left: parent.left
                    anchors.leftMargin: 10
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
                    anchors.rightMargin: 10
                }
            }
        }

        Component {
            id: delegateComponent
            Button {
                width: listView.width
                height: 60
                flat: true
                topInset: 0
                bottomInset: 0
                Material.roundedScale: Material.NotRounded

                IconLabel {
                    id: iconLabel
                    height: parent.height / 2
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    icon.source: window.typeIcons[config["type"]]
                    anchors.leftMargin: 10
                }
                Label {
                    height: iconLabel.height / 5 * 3
                    width: contentWidth
                    anchors.bottom: iconLabel.bottom
                    fontSizeMode: Text.VerticalFit
                    minimumPixelSize: 10
                    font.pixelSize: 72
                    anchors.left: iconLabel.right
                    anchors.leftMargin: 10
                    text: {
                        var ret = ""
                        var entries = Object.entries(config)
                        for (var i = 0; i < entries.length; ++i) {
                            if (entries[i][0] === "address" || entries[i][0] === "type" || entries[i][0] === "connected") {
                                continue
                            }
                            if (ret !== "") {
                                ret += qsTr(", ")
                            }
                            ret += entries[i][1]
                        }
                        if (ret === "") {
                            ret = config["address"]
                        }
                        return ret
                    }
                }
                Button {
                    id: connectButton
                    height: parent.height / 2
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    flat: true
                    topInset: 0
                    bottomInset: 0
                    Material.roundedScale: Material.FullScale
                    highlighted: config["connected"]

                    IconLabel {
                        anchors.centerIn: parent
                        icon.width: parent.width / 5 * 4
                        icon.height: parent.width / 5 * 4
                        icon.source: config["connected"] ? "/icons/connect.svg" : "/icons/disconnect.svg"
                        icon.color: parent.icon.color
                    }
                }

                Button {
                    height: parent.height / 2
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: connectButton.left
                    anchors.rightMargin: 10
                    flat: true
                    topInset: 0
                    bottomInset: 0
                    Material.roundedScale: Material.FullScale
                    highlighted: config["connected"]
                    enabled: config["connected"]

                    IconLabel {
                        anchors.centerIn: parent
                        icon.width: parent.width / 5 * 4
                        icon.height: parent.width / 5 * 4
                        icon.source: "/icons/config.svg"
                        icon.color: parent.icon.color
                    }
                }
            }
        }
    }

    data: Dialog {
        id: filterDialog
        anchors.centerIn: parent
        parent: Overlay.overlay
        focus: true
        modal: true
        title: qsTr("Filter")
        standardButtons: Dialog.Ok | Dialog.Reset | Dialog.Cancel
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
