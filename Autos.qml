import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as J

C.List {
    id: viewsList

    model: ListModel {
        id: listModel
    }
    Component.onCompleted: {
        for (var i = 0; i < root.views.length; ++i) {
            listModel.append({view: root.views[i]})
        }
    }
    delegate: Component {
        C.Touch {
            width: viewsList.width
            height: 87

            contentItem: Item {
                ListView {
                    id: iconsListView
                    anchors.left: parent.left
                    anchors.top: parent.top
                    height: 32
                    width: 200
                    interactive: false
                    orientation: ListView.Horizontal
                    spacing: 10
                    model: ListModel {
                        id: iconsListModel
                    }
                    Component.onCompleted: {
                        var viewStates = view["states"]
                        for (var i = 0; i < viewStates.length; ++i) {
                            iconsListModel.append({ furniture: viewStates[i] })
                        }
                    }
                    delegate: Component {
                        C.Rounded {
                            property int furnitureIndex: J.find(root.furnitures, "address", furniture["address"])
                            height: iconsListView.height
                            width: height
                            icon.source: furnitureIndex === -1 ?
                                             "/icons/disconnected.svg" :
                                             root.typeIcons[root.furnitures[furnitureIndex]["type"]]
                            highlighted: furniture["state"] > 0
                            Material.accent: furnitureIndex === -1 ?
                                                 iconsListView.Material.accent :
                                                 root.stateIcons[root.furnitures[furnitureIndex]["type"]][furniture["state"]]
                        }
                    }
                }
                C.VFit {
                    id: viewVFit
                    anchors.left: iconsListView.left
                    anchors.top: iconsListView.bottom
                    anchors.topMargin: 10
                    anchors.right: autoVFit.left
                    anchors.rightMargin: 10
                    height: 16
                    clip: true
                    text: {
                        var viewAlias = view["alias"]
                        if (viewAlias !== undefined) {
                            return viewAlias
                        }
                        return ""
                    }
                }
                property int autoIndex: J.find(root.autos, "view", view["uid"])
                C.VFit {
                    id: autoVFit
                    anchors.right: parent.right
                    anchors.bottom: viewVFit.bottom
                    height: viewVFit.height
                    font.underline: true
                    text: {
                        if (parent.autoIndex === -1) {
                            return ""
                        }
                        var auto = root.autos[parent.autoIndex]
                        var autoStart = auto["start"] * 1000
                        var ret = ""
                        if (autoStart !== undefined) {
                            ret += new Date(autoStart).toLocaleString()
                        }
                        return ret
                    }
                }
                RowLayout {
                    height: 32
                    anchors.verticalCenter: iconsListView.verticalCenter
                    anchors.right: parent.right
                    spacing: 10

                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: true
                        icon.source: "/icons/config.svg"
                    }
                    C.Rounded {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        highlighted: true
                        icon.source: parent.parent.autoIndex === -1 ? "/icons/timeout.svg" : "/icons/play.svg"
                    }
                }
            }
        }
    }
}
