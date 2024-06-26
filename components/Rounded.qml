﻿import QtQuick
import "." as C
import QtQuick.Controls
import QtQuick.Layouts

Button {
    flat: true
    topInset: 0
    bottomInset: 0
    leftInset: 0
    rightInset: 0
    padding: 10
    Material.roundedScale: Material.FullScale
    display: AbstractButton.TextOnly
    width: root.roundedSize
    height: root.roundedSize
    Layout.preferredHeight: root.roundedSize
    Layout.preferredWidth: root.roundedSize

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
