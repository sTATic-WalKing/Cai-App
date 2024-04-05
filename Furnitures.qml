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
            ListElement { e: "s" }
            ListElement { e: "s" }
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
                Component.onCompleted: {
                    updateFilterLabel()
                }
                onClicked: {
                    filterDialog.open()
                }

                function updateFilterLabel(){
                    filterLabel.text = ""
                    var entries = Object.entries(filters)
                    for (var i = 0; i < entries.length; ++i) {
                        if (i > 0) {
                            filterLabel.text += qsTr(", ")
                        }
                        if (entries[i][0] === "type") {
                            filterLabel.text += window.typeTexts[entries[i][1]]
                        } else {
                            filterLabel.text += entries[i][1]
                        }
                    }
                    if (filterLabel.text === "") {
                        filterLabel.text = qsTr("No filter")
                    }
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
                height: 87
                flat: true
                topInset: 0
                bottomInset: 0
                Material.roundedScale: Material.NotRounded
            }
        }
    }

    data: Dialog {
        id: filterDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
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
