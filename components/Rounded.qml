import QtQuick
import "." as C
import QtQuick.Controls
import QtQuick.Layouts

C.Touch {
    Material.roundedScale: Material.FullScale
    display: AbstractButton.TextOnly

    IconLabel {
        anchors.centerIn: parent
        icon.width: parent.width / 5 * 4
        icon.height: parent.width / 5 * 4
        icon.source: parent.icon.source
        icon.color: parent.icon.color
    }
}
