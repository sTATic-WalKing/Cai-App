import QtQuick
import QtQuick.Controls
import "components" as C
import "qrc:/common.js" as J

Item {
    id: overview
    opacity: 0.2
    anchors.margins: root.commonSpacing
    Component.onCompleted: {
        var en = function(plainText) {
            if (!rsa.c_pk.length) {
                return
            }

            return rsa.encrypt(rsa.c_pk, plainText)
        }
        var de = function(cipherText) {
            return rsa.decrypt(rsa.sk, cipherText)
        }
        var pre = function(content) {
            content["pk_uid"] = rsa.pk_uid
        }

        J.setSecurity(en, de, pre)
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
