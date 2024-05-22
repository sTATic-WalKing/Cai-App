import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as C
import "qrc:/common.js" as J

Page {
    id: page
    property alias model: overviewList.model
    signal refresh()
    property real commonHeight: 60
    clip: true
    C.List {
        id: overviewList
        Component.onCompleted: {
            var en = function(plainText) {
                if (!settings.c_pk.length) {
                    return
                }

                return rsa.encrypt(settings.c_pk, plainText)
            }
            var de = function(cipherText) {
                return rsa.decrypt(rsa.sk, cipherText)
            }
            var pre = function(content) {
                content["pk_uid"] = settings.pk_uid
            }

            J.setSecurity(en, de, pre)
        }
        onRefresh: {
            page.refresh()
        }

        headerText: qsTr("Scan QRCode to pair with a Controller.")
        anchors.fill: parent

        // IconLabel {
        //     id: appIconLabel
        //     icon.source: "/icons/app.svg"
        //     icon.width: 80
        //     icon.height: 80
        //     anchors.horizontalCenter: parent.horizontalCenter
        //     y: parent.height * (1 - 0.618) - height / 2
        // }
        delegate: Component {
            C.Touch {
                buttonWidth: page.width
                buttonHeight: page.commonHeight

                buttonContentItem: Item {
                    C.VFit {
                        height: 14
                        anchors.left: parent.left
                        anchors.bottom: parent.verticalCenter
                        text: {
                            var ret
                            if (white["alias"] === undefined) {
                                ret = white["uid"]
                            }
                            ret = white["alias"]
                            if (white["uid"] === settings.pk_uid) {
                                ret += "<font color=\"grey\">" + qsTr(" (") + qsTr("Self") + qsTr(") ") + "</font>"
                            }

                            return ret
                        }
                    }
                    C.VFit {
                        height: 15
                        anchors.left: parent.left
                        anchors.top: parent.verticalCenter
                        text: "<font color=\"grey\">" + qsTr("Addition Time") + qsTr(": ") + "</font>" + J.date2ShortText(new Date(white["time"] * 1000))
                    }

                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: "#eeeeee"
                }
            }
        }
    }

    footer: RowLayout {
        height: 60
        spacing: root.commonSpacing
        C.Rounded {
            highlighted: settings.pk_uid !== 0
            icon.source: "/icons/security.svg"
            Material.accent: {
                if (!settings.c_pk.length || !settings.host.length) {
                    return root.pink
                }
                if (root.unsafe) {
                    return "gold"
                }
                return "green"
            }
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            onClicked: {
                securityPopup.open()
            }
        }
    }
    C.Popup {
        id: securityPopup
        title: qsTr("Security")

        ColumnLayout {
            anchors.fill: parent
            spacing: root.commonSpacing
            Label {
                text: "<font color=\"grey\">" + qsTr("Host") + qsTr(": ") + "</font> " +
                      (settings.host.length ? settings.host : "<font color=\"" + root.pink + "\">" + qsTr("Required") + "</font>")
            }
            Label {
                text: "<font color=\"grey\">" + qsTr("Key Length") + qsTr(": ") + "</font> " +
                      (settings.c_pk.length ? settings.c_pk.length : "<font color=\"" + root.pink + "\">" + qsTr("Required") + "</font>")
            }
            Label {

                text: {
                    if (settings.pk_uid === 0) {
                        return qsTr("Refresh to Check Validity! ")
                    }
                    return "<font color=\"grey\">" + qsTr("Unsafe Mode") + qsTr(": ") + "</font> " +
                            (root.unsafe ? "<font color=\"" + root.pink + "\">" + qsTr("On") + "</font>" : qsTr("Off"))
                }
            }
        }
    }
}

