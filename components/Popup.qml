import QtQuick
import QtQuick.Controls

Dialog {
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: parent.width
    Material.roundedScale: Material.NotRounded
    modal: true
    focus: true
}
