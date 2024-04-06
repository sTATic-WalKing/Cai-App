import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C

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
            C.Touch {
                width: listView.width
                height: 87

                contentItem: Item {

                }
            }
        }
    }
}
