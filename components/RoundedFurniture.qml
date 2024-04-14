import QtQuick
import "." as C
import QtQuick.Controls
import "qrc:/common.js" as J

C.Rounded {
    required property var furniture
    property int furnitureIndex: J.find(root.furnitures, "address", furniture["address"])
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
