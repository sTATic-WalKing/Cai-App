import QtQuick
import "." as C
import QtQuick.Controls
import QtQuick.Layouts

C.Touch {
    Material.roundedScale: Material.FullScale
    display: AbstractButton.TextOnly

    IconLabel {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (parent.height - height) / 2
        icon.width: parent.width / 5 * 4
        icon.height: parent.width / 5 * 4
        icon.source: parent.icon.source
        icon.color: parent.icon.color
    }

}
