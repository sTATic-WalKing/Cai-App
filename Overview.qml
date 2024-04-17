import QtQuick
import QtQuick.Controls
import "components" as C
import "qrc:/common.js" as J

Item {
    id: overview
    opacity: 0.2
    anchors.margins: root.commonSpacing

    IconLabel {
        id: appIconLabel
        icon.source: "/icons/app.svg"
        icon.width: 80
        icon.height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * (1 - 0.618) - height / 2
    }
}
