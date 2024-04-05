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

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56

        Label {
            id: filterLabel
            height: parent.height / 3
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
