import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as Common

Flickable {
    id: flickable

    required property var furnitures
    required property var autos
    property var filters: ({})

    contentHeight: listView.height
    ListView {
        id: listView
        width: flickable.width
        height: flickable.height
        delegate: delegateComponent
        header: headerComponent
        headerPositioning: ListView.PullBackHeader

        model: ListModel {
            id: listModel
        }

        Component.onCompleted: {
            Common.updateModelData(listModel, furnitures, "furniture", "address")
        }

        Shortcut {
            sequence: "Ctrl+N"
            onActivated: {
                var datas = [
                    { "address": "11:11:11:11:11:11", "type": 0, "connected": true, "alias": "刚修好的台灯", "loc": "客厅" },
                    { "address": "22:22:22:22:22:22", "type": 0, "connected": true, "alias": "刚买的台灯" },
                    { "address": "33:33:33:33:33:33", "type": 0, "connected": false, "loc": "大房间" },
                    { "address": "55:55:55:55:55:55", "type": 0, "connected": true, "alias": "新添加的台灯" }
                ]
                Common.updateModelData(listModel, datas, "furniture", "address")
            }
        }

        Component {
            id: headerComponent
            C.Touch {
                height: 56
                width: listView.width
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
                    }
                }
            }
        }

        Component {
            id: delegateComponent
            C.Touch {
                width: listView.width
                height: 60

                contentItem: Item {
                    IconLabel {
                        id: iconLabel
                        height: parent.parent.height / 2
                        width: height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        icon.source: window.typeIcons[furniture["type"]]
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
                            var entries = Object.entries(furniture)
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
