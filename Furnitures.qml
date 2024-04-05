import QtQuick
 import QtQuick.Controls

Item {
    id: root

    required property color foreground
    required property var furnitures
    property var filters: ({ "type": 0, "alias": "台灯", "loc": "厨房" })

    function updateFilterLabel(){
        filterLabel.text = ""
        for (value in filters.values) {
            filterLabel.text += value + " "
        }
        if (filterLabel.text === "") {
            filterLabel.text = qsTr("No filter")
        }
    }

    function onEnter() {
        updateFilterLabel()
    }

    Button {
        id: filterButton
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        flat: true
        topInset: 0
        bottomInset: 0

        Component.onCompleted: {
            filterButton.background.radius = 0
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
            icon.source: "/icons/triangle_downward.svg"
            anchors.rightMargin: 10
        }

    }
}
