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
                            icon.source: {
                                if (furnitureIndex === -1) {
                                    return "/icons/delete.svg"
                                }
                                if (!root.furnitures[furnitureIndex]["connected"]) {
                                    return "/icons/disconnected.svg"
                                }
                                return root.typeIcons[root.furnitures[furnitureIndex]["type"]]
                            }

                            highlighted: furniture["state"] > 0 || furnitureIndex === -1 || !root.furnitures[furnitureIndex]["connected"]
                            Material.accent: furnitureIndex === -1 || !root.furnitures[furnitureIndex]["connected"] ?
                                                 "#E91E63" :
                                                 root.stateIcons[root.furnitures[furnitureIndex]["type"]][furniture["state"]]
                            ToolTip.visible: down
                            ToolTip.text: {
                                if (furnitureIndex === -1) {
                                    return qsTr("Deleted")
                                }
                                var rootFurniture = root.furnitures[furnitureIndex]
                                var furnitureAlias = rootFurniture["alias"]
                                if (furnitureAlias !== undefined) {
                                    return furnitureAlias
                                }
                                return rootFurniture["address"]
                            }
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
                property var autoIndexes: {
                    var ret = J.findAll(root.autos, "view", view["uid"])
                    ret.sort(function(a, b) { return root.autos[a]["start"] - root.autos[b]["start"] })
                    return ret
                }

                C.VFit {
                    id: autoVFit
                    anchors.right: parent.right
                    anchors.bottom: viewVFit.bottom
                    height: viewVFit.height
                    font.underline: true
                    enabled: parent.autoIndexes.length !== 0
                    text: {
                        if (parent.autoIndexes.length === 0) {
                            return qsTr("Failed to get the next start time.")
                        }
                        var auto = root.autos[parent.autoIndexes[0]]
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
                        icon.source: parent.parent.autoIndexes.length === 0 ? "/icons/timeout.svg" : "/icons/play.svg"
                    }
                }
            }
        }
    }
}
