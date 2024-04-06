import QtQuick
import QtQuick.Controls

ListView {
    id: listView
    headerPositioning: ListView.PullBackHeader

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
        }
    }
}
