import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: flickable

    required property var views

    contentHeight: listView.height
    ListView {
        id: listView
        width: flickable.width
        height: flickable.height
        delegate: delegateComponent

        model: ListModel {
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

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.verticalCenter

                }
            }
        }
    }
}
