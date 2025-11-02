import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 6.5
import Sddm 1.1

Item {
    width: 1920; height: 1080
    property color fg: "#ffffff"
    property color ac: "#7aa2f7"
    property int fs: 14

    // --- video background ---
    MediaPlayer {
        id: player
        source: theme.background
        autoPlay: true
        loops: MediaPlayer.Infinite
        muted: true
    }
    VideoOutput {
        anchors.fill: parent
        source: player
        fillMode: VideoOutput.PreserveAspectCrop
    }

    // --- overlay ---
    Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
        anchors.fill: parent
    }

    ColumnLayout {
        width: 280
        spacing: 10
        anchors.centerIn: parent

        Label {
            text: "login"
            color: fg
            font.pixelSize: fs + 4
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: user
            placeholderText: "username"
            color: fg
            Layout.fillWidth: true
            font.pixelSize: fs
            onAccepted: password.forceActiveFocus()
        }

        TextField {
            id: password
            placeholderText: "password"
            echoMode: TextInput.Password
            color: fg
            Layout.fillWidth: true
            font.pixelSize: fs
            onAccepted: loginButton.clicked()
        }

        Button {
            id: loginButton
            text: "log in"
            Layout.fillWidth: true
            background: Rectangle { color: ac; radius: 3 }
            contentItem: Label {
                text: loginButton.text
                color: "#000"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                sddm.login(user.text, password.text, sddm.session)
            }
        }

        Label {
            text: sddm.loginFailed ? "login failed" : ""
            color: "#ff5555"
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // small power buttons bottom right
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 8

        Button {
            text: "reboot"
            onClicked: sddm.reboot()
        }
        Button {
            text: "power off"
            onClicked: sddm.powerOff()
        }
    }
}

