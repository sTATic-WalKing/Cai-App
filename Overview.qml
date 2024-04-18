import QtQuick
import QtQuick.Controls
import "components" as C
import "qrc:/common.js" as J

Item {
    id: overview
    opacity: 0.2
    anchors.margins: root.commonSpacing

    function hash_info() {
        var related_configs = []
        for (var i = 0; i < root.furnitures.length; ++i) {
            var related_config = {}
            related_config["address"] = root.furnitures[i]["address"]
            related_config["connected"] = root.furnitures[i]["connected"]
            related_config["state"] = root.furnitures[i]["state"]
            related_config["type"] = root.furnitures[i]["type"]
            related_configs.push(related_config)
        }
        related_configs.sort(function(a, b) { return a["address"] < b["address"] })
        var view_uids = []
        for (i = 0; i < root.views.length; ++i) {
            view_uids.push(root.views[i]["uid"])
        }
        view_uids.sort()
        var auto_uids = []
        for (i = 0; i < root.autos.length; ++i) {
            auto_uids.push(root.autos[i]["uid"])
        }
        auto_uids.sort()
        var str = JSON.stringify([ related_configs, view_uids, auto_uids ]).replace(" ", "")
        var hashed = Qt.md5(str)
        return hashed
    }

    Timer {
        interval: 8 * 1000
        repeat: true
        Component.onCompleted: {
            start()
        }
        onTriggered: {
            var onPostJsonComplete = function(rsp) {
                if (rsp["hash"] !== hash_info()) {
                    refreshPopup.open()
                }
            }
            J.postJSON(settings.host + "/ping", onPostJsonComplete, root.xhrErrorHandle, {}, false)
        }
    }

    IconLabel {
        id: appIconLabel
        icon.source: "/icons/app.svg"
        icon.width: 80
        icon.height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * (1 - 0.618) - height / 2
    }
}
