import QtQuick
import QtQuick.Controls

Item {
    property alias button: innerButton
    property alias buttonHeight: innerButton.height
    property alias buttonWidth: innerButton.width
    property alias buttonContentItem: innerButton.contentItem
    property alias buttonText: innerButton.text
    signal buttonClicked()
    property real extraHeight
    property real extraWidth
    property bool displayExtra

    function updateSize() {
        if (displayExtra) {
            heightNumberAnimation.to = extraHeight + buttonHeight
            widthNumberAnimation.to = extraWidth + buttonWidth
        } else {
            heightNumberAnimation.to = buttonHeight
            widthNumberAnimation.to = buttonWidth
        }
        heightNumberAnimation.start()
        widthNumberAnimation.start()
    }

    clip: true
    width: buttonWidth
    height: buttonHeight
    onDisplayExtraChanged: {
        updateSize()
    }
    onButtonClicked: {
        displayExtra = !displayExtra
    }

    Button {
        id: innerButton
        flat: true
        topInset: 0
        bottomInset: 0
        leftInset: 0
        rightInset: 0
        Material.roundedScale: Material.NotRounded
        padding: 10
        onClicked: {
            parent.buttonClicked()
        }
    }

    readonly property int duration: 50
    NumberAnimation on height {
        id: heightNumberAnimation
        duration: duration
    }
    NumberAnimation on width {
        id: widthNumberAnimation
        duration: duration
    }
}
