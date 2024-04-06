import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: flickable

    property var delegate: Item {}
    property var model: ListModel {}
    property var header

    contentHeight: listView.height
    ListView {
        id: listView
        width: flickable.width
        height: flickable.height
        delegate: flickable.delegate
        header: flickable.header
        headerPositioning: ListView.PullBackHeader
        model: flickable.model
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

    }
}
