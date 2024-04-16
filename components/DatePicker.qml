import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as C

ColumnLayout {
    function date2Stamp(date) {
        var stamp = parseInt(date.getTime() / 1000)
        return stamp - stamp % (24 * 60 * 60)
    }

    property int selectedDate
    function reset() {
        grid.clicked(root.currentDate)
    }

    readonly property real delegateSize: 32
    DayOfWeekRow {
        locale: grid.locale
        delegate: Label {
            text: shortName
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: Material.primary
            width: delegateSize
            height: width
        }
    }
    MonthGrid {
        id: grid
        property real selectedX
        property real selectedY
        property real selectedWidth
        property real selectedHeight
        property real selectedOpacity
        month: monthSpinBox.value
        year: yearSpinBox.value
        locale: Qt.locale()
        delegate: Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            enabled: model.month === grid.month
            text: model.day
            width: delegateSize
            height: width

            readonly property bool selected: selectedDate === date2Stamp(model.date)
            onSelectedChanged: {
                if (selected) {
                    grid.selectedX = x
                    grid.selectedY = y
                    grid.selectedWidth = width
                    grid.selectedHeight = height
                    xNumberAnimation.start()
                    yNumberAnimation.start()
                    widthNumberAnimation.start()
                    heightNumberAnimation.start()
                    opacityNumberAnimation.start()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Material.primary
                opacity: 0.2
                visible: {
                    var current = new Date()
                    return current.getFullYear() === model.year && current.getMonth() === model.month && current.getDate() === model.day
                }
            }
        }
        onClicked: (date) => {
                       selectedOpacity = (date.getFullYear() === yearSpinBox.value && date.getMonth() === monthSpinBox.value) ? 1 : 0
                       selectedDate = date2Stamp(date)
        }
        Rectangle {
            color: "transparent"
            border.width: 1
            border.color: Material.accent
            readonly property int duration: 50

            NumberAnimation on x {
                id: xNumberAnimation
                duration: duration
                to: grid.selectedX
            }
            NumberAnimation on y {
                id: yNumberAnimation
                duration: duration
                to: grid.selectedY
            }
            NumberAnimation on width {
                id: widthNumberAnimation
                duration: duration
                to: grid.selectedWidth
            }
            NumberAnimation on height {
                id: heightNumberAnimation
                duration: duration
                to: grid.selectedHeight
            }
            NumberAnimation on opacity {
                id: opacityNumberAnimation
                duration: duration
                from: 1
                to: grid.selectedOpacity
            }
        }
    }
    SpinBox {
        id: monthSpinBox
        Layout.preferredWidth: grid.width
        from: 0
        to: 11
        Component.onCompleted: {
            value = new Date().getMonth()
        }
        textFromValue: function(value, locale) {
            var months = [qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"), qsTr("May"), qsTr("June"), qsTr("July"), qsTr("August"), qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December")]
            return months[Number(value)]
        }
    }
    SpinBox {
        id: yearSpinBox
        Layout.preferredWidth: grid.width
        from: -271820
        to: 275759
        Component.onCompleted: {
            value = new Date().getFullYear()
        }
    }

}
