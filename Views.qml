import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as Common

C.List {
    id: viewsList

    // required property var furnitures
    // required property var views

    // delegate: delegateComponent
    // model: ListModel {
    //     id: listModel
    // }

    // Component {
    //     id: delegateComponent

    //     C.Touch {
    //         width: viewsList.width
    //         height: 87

    //         contentItem: Item {
    //             RowLayout {
    //                 id: iconsRowLayout
    //                 anchors.left: parent.left
    //                 anchors.bottom: parent.verticalCenter
    //                 height: 15
    //                 Repeater {
    //                     model: view["states"]
    //                     C.Rounded {
    //                         height: iconsRowLayout.height
    //                         width: height
    //                         anchors.verticalCenter: parent.verticalCenter
    //                         anchors.left: parent.left
    //                         icon.source: {
    //                             var index = Common.find(furnitures, "address", address)
    //                             if (index === -1) {
    //                                 return "/icons/disconnected.svg"
    //                             }
    //                             root.typeIcons[furnitures[index]["type"]]
    //                         }
    //                         highlighted: state > 0
    //                         Material.accent: { //
    //                             var index = Common.find(furnitures, "address", address)
    //                             if (index === -1) {
    //                                 return Material.accent
    //                             }
    //                             var furniture = furnitures[index]
    //                             return root.stateIcons[furniture["type"]][furniture["state"]]
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }
}
