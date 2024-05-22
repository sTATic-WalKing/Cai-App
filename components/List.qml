import QtQuick
import QtQuick.Controls
import "." as C

ListView {
    id: listView
    headerPositioning: ListView.PullBackHeader
    property string headerText: qsTr("Nothing here, and Pull to Refresh.")

    readonly property real duration: 150
    add: Transition {
        NumberAnimation { properties: "x"; from: listView.width; duration: duration }
    }
    remove: Transition {
        NumberAnimation { properties: "x"; to: -listView.width; duration: duration }
    }
    displaced: Transition {
        NumberAnimation { properties: "y"; duration: duration }
    }

    property bool bRefresh
    readonly property real overContentY: -80
    readonly property bool bOver: {
        var offset = 0
        if (listView.headerItem) {
            offset = listView.headerItem.height
        }
        return contentY + offset <= overContentY
    }
    signal refresh()
    onMovementEnded: {
        if (atYBeginning && bRefresh) {
            refresh()
        }
    }
    onDragEnded: {
        bRefresh = bOver
    }

    Item {
        anchors.bottom: contentItem.top
        anchors.left: contentItem.left
        anchors.right: contentItem.right
        anchors.bottomMargin: listView.count > 0 || !headerItem ? 0 : headerItem.height
        clip: true
        height: {
            var offset = 0
            if (listView.headerItem) {
                offset = -listView.headerItem.height
            }
            return Math.max(0, listView.contentItem.y + offset)
        }
        IconLabel {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 10
            height: 36
            icon.source: listView.bOver ? "/icons/refresh.svg" : "/icons/down.svg"
            icon.color: root.pink
        }
    }

    header: Component {
        Item {
            height: listView.count > 0 ? 0 : 56
            width: listView.width
            clip: true

            C.VFit {
                height: parent.height / 3
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                font.italic: true
                text: listView.headerText
                enabled: false
            }
        }
    }
}
