import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
    property bool daySpinBoxVisible: false
    readonly property real colonSize: 12
    readonly property int selectedTime: (daySpinBoxVisible ? dayTumbler.currentIndex * 24 * 60 * 60 : 0) +
                                        hourTumbler.currentIndex * 60 * 60 +
                                        minuteTumbler.currentIndex * 60 +
                                        secondTumbler.currentIndex

    spacing: 0
    Tumbler {
        id: dayTumbler
        model: 100
        visible: daySpinBoxVisible

        ToolTip.text: qsTr("Days")
        ToolTip.visible: hovered
    }
    IconLabel {
        icon.source: "/icons/left.svg"
        Layout.preferredWidth: colonSize
        Layout.preferredHeight: colonSize
        visible: daySpinBoxVisible
    }
    Tumbler {
        id: hourTumbler
        model: 24

        ToolTip.text: qsTr("Hours")
        ToolTip.visible: hovered
    }
    IconLabel {
        icon.source: "/icons/colon.svg"
        Layout.preferredWidth: colonSize
        Layout.preferredHeight: colonSize
    }
    Tumbler {
        id: minuteTumbler
        model: 60

        ToolTip.text: qsTr("Minutes")
        ToolTip.visible: hovered
    }
    IconLabel {
        icon.source: "/icons/colon.svg"
        Layout.preferredWidth: colonSize
        Layout.preferredHeight: colonSize
    }
    Tumbler {
        id: secondTumbler
        model: 60

        ToolTip.text: qsTr("Seconds")
        ToolTip.visible: hovered
    }
}
