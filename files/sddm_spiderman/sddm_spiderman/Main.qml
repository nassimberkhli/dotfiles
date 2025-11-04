import QtQuick 2.15
import QtQuick.Controls 2.0
import SddmComponents 2.0
import QtMultimedia
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 640
    height: 480

    // --- propriétés dérivées de la config ---
    readonly property color textColor: config.stringValue("basicTextColor")
    property int currentUsersIndex: userModel.lastIndex
    property int currentSessionsIndex: sessionModel.lastIndex
    property int usernameRole: Qt.UserRole + 1
    property int realNameRole: Qt.UserRole + 2
    property int sessionNameRole: Qt.UserRole + 4

    // user courant selon le réglage "showUserRealNameByDefault"
    property string currentUsername: config.boolValue("showUserRealNameByDefault")
                                     ? userModel.data(userModel.index(currentUsersIndex, 0), realNameRole)
                                     : userModel.data(userModel.index(currentUsersIndex, 0), usernameRole)

    property string currentSession: sessionModel.data(sessionModel.index(currentSessionsIndex, 0), sessionNameRole)

    property int passwordFontSize:  config.intValue("passwordFontSize")  || 96
    property int usersFontSize:     config.intValue("usersFontSize")     || 48
    property int sessionsFontSize:  config.intValue("sessionsFontSize")  || 24
    property int helpFontSize:      config.intValue("helpFontSize")      || 18
    property string defaultFont:    config.stringValue("font")           || "monospace"
    property string helpFont:       config.stringValue("helpFont")       || defaultFont

    // --- helpers sélection utilisateurs ---
    function usersCycleSelectPrev() {
        if (currentUsersIndex - 1 < 0) {
            currentUsersIndex = userModel.count - 1;
        } else {
            currentUsersIndex--;
        }
    }
    function usersCycleSelectNext() {
        if (currentUsersIndex >= userModel.count - 1) {
            currentUsersIndex = 0;
        } else {
            currentUsersIndex++;
        }
    }

    // --- helpers sélection sessions ---
    function sessionsCycleSelectPrev() {
        if (currentSessionsIndex - 1 < 0) {
            currentSessionsIndex = sessionModel.rowCount() - 1;
        } else {
            currentSessionsIndex--;
        }
    }
    function sessionsCycleSelectNext() {
        if (currentSessionsIndex >= sessionModel.rowCount() - 1) {
            currentSessionsIndex = 0;
        } else {
            currentSessionsIndex++;
        }
    }

    // --- mode de remplissage du fond ---
    function bgFillMode() {
        switch (config.stringValue("backgroundFillMode")) {
        case "aspect": return Image.PreserveAspectCrop;
        case "fill":   return Image.Stretch;
        case "tile":   return Image.Tile;
        case "pad":    return Image.Pad;
        default:       return Image.Pad;
        }
    }

    // --- réactions sddm ---
    Connections {
        target: sddm
        function onLoginFailed() {
            backgroundBorder.border.width = 5;
            animateBorder.restart();
            passwordInput.clear();
        }
        function onLoginSucceeded() {
            backgroundBorder.border.width = 0;
            animateBorder.stop();
        }
    }

    // --- zone principale plein écran ---
    Item {
        id: mainFrame
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x; y: geometry.y
        width: geometry.width; height: geometry.height

        // --- raccourcis clavier ---
        Shortcut { sequences: ["Alt+U", "F2"]; onActivated: { if (!username.visible) { username.visible = true; return; } usersCycleSelectNext(); } }
        Shortcut { sequences: ["Alt+Ctrl+U", "Ctrl+F2"]; onActivated: { if (!username.visible) { username.visible = true; return; } usersCycleSelectPrev(); } }
        Shortcut { sequences: ["Alt+S", "F3"]; onActivated: { if (!sessionName.visible) { sessionName.visible = true; return; } sessionsCycleSelectNext(); } }
        Shortcut { sequences: ["Alt+Ctrl+S", "Ctrl+F3"]; onActivated: { if (!sessionName.visible) { sessionName.visible = true; return; } sessionsCycleSelectPrev(); } }
        Shortcut { sequence: "F10"; onActivated: { if (sddm.canSuspend)  sddm.suspend(); } }
        Shortcut { sequence: "F11"; onActivated: { if (sddm.canPowerOff) sddm.powerOff(); } }
        Shortcut { sequence: "F12"; onActivated: { if (sddm.canReboot)   sddm.reboot(); } }
        Shortcut { sequence: "F1";  onActivated: helpMessage.visible = !helpMessage.visible }

        // --- fond ---
        Rectangle {
            id: background
            anchors.fill: parent
            visible: true
            color: config.stringValue("backgroundFill") || "transparent"

            // conteneur qui gère image ou vidéo
            Item {
                id: image
                anchors.fill: parent
                z: 2

                property string bg: config.stringValue("background")
                property bool isVideo: /\.(mp4|webm|mkv|mov|m4v)$/i.test(bg)

                // image fixe
                Image {
                    anchors.fill: parent
                    visible: !image.isVideo
                    source: image.bg
                    smooth: true
                    fillMode: bgFillMode()
                }

                // vidéo de fond
                MediaPlayer {
                    id: player
                    source: image.bg
                    loops: MediaPlayer.Infinite
                    autoPlay: image.isVideo
                    audioOutput: AudioOutput { muted: true }
                    onErrorOccurred: console.warn("Video error:", errorString)
                }

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                    visible: image.isVideo
                    fillMode: (config.stringValue("backgroundFillMode") === "fill")
                              ? VideoOutput.Stretch
                              : VideoOutput.PreserveAspectCrop
                    Component.onCompleted: player.videoOutput = videoOutput
                }
            }

            // cadre rouge en cas d'échec
            Rectangle {
                id: backgroundBorder
                anchors.fill: parent
                z: 4
                color: "transparent"
                radius: config.stringValue("wrongPasswordBorderRadius") || 0
                border.color: config.stringValue("wrongPasswordBorderColor") || "#ff3117"
                border.width: 0

                Behavior on border.width {
                    SequentialAnimation {
                        id: animateBorder
                        running: false
                        loops: Animation.Infinite
                        NumberAnimation { from: 5; to: 10; duration: 700 }
                        NumberAnimation { from: 10; to: 5; duration: 400 }
                    }
                }
            }

            // flou appliqué au conteneur (image ou vidéo)
            FastBlur {
                id: fastBlur
                anchors.fill: parent
                z: 3
                source: image
                radius: config.intValue("blurRadius")
            }
        }

        // --- champ mot de passe ---
        TextInput {
            id: passwordInput
            width: parent.width * (config.realValue("passwordInputWidth") || 0.5)
            height: 200/96 * passwordFontSize
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            font.pointSize: passwordFontSize
            font.bold: true
            font.letterSpacing: 20/96 * passwordFontSize
            font.family: defaultFont

            echoMode: config.boolValue("passwordMask") ? TextInput.Password : TextInput.Normal
            color: config.stringValue("passwordTextColor") || textColor
            selectionColor: textColor
            selectedTextColor: "#000000"
            clip: true
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            passwordCharacter: config.stringValue("passwordCharacter") || "*"
            cursorVisible: config.boolValue("passwordInputCursorVisible")

            onAccepted: {
                if (text !== "" || config.boolValue("passwordAllowEmpty")) {
                    sddm.login(
                        userModel.data(userModel.index(currentUsersIndex, 0), usernameRole) || "123test",
                        text,
                        currentSessionsIndex
                    );
                }
            }

            // fond du champ
            Rectangle {
                z: -1
                anchors.fill: parent
                color: config.stringValue("passwordInputBackground") || "transparent"
                radius: config.intValue("passwordInputRadius") || 10
                border.width: config.intValue("passwordInputBorderWidth") || 0
                border.color: config.stringValue("passwordInputBorderColor") || "#ffffff"
            }

            // curseur custom
            cursorDelegate: Rectangle {
                id: passwordInputCursor
                width: 18/96 * passwordFontSize
                visible: config.boolValue("passwordInputCursorVisible")
                anchors.verticalCenter: parent.verticalCenter

                function generateRandomColor() {
                    var color_ = "#";
                    for (var i = 0; i < 3; i++) {
                        var n = parseInt(Math.random() * 255);
                        var hex = n.toString(16);
                        if (n < 16) hex = "0" + hex;
                        color_ += hex;
                    }
                    return color_;
                }

                function getCursorColor() {
                    var value = config.stringValue("passwordCursorColor");
                    if (value.length === 7 && value[0] === "#") {
                        return value;
                    } else if (value === "random" || value === "constantRandom") {
                        return generateRandomColor();
                    }
                    return textColor;
                }

                color: getCursorColor()
                onHeightChanged: height = passwordInput.height / 2

                property color currentColor: color

                SequentialAnimation on color {
                    loops: Animation.Infinite
                    PauseAnimation { duration: 100 }
                    ColorAnimation { from: currentColor; to: "transparent"; duration: 0 }
                    PauseAnimation { duration: 500 }
                    ColorAnimation { from: "transparent"; to: currentColor; duration: 0 }
                    PauseAnimation { duration: 400 }
                    running: config.boolValue("cursorBlinkAnimation")
                }

                Connections {
                    target: passwordInput
                    function onTextEdited() {
                        if (config.stringValue("passwordCursorColor") === "random") {
                            passwordInputCursor.currentColor = passwordInputCursor.generateRandomColor();
                        }
                    }
                }
            }
        }

        // --- sélection utilisateurs ---
        UsersChoose {
            id: username
            text: currentUsername
            visible: config.boolValue("showUsersByDefault")
            width: mainFrame.width / 2.5 / 48 * usersFontSize
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
	    anchors.topMargin: 30
            // anchors.parent: passwordInput.top
            // anchors.bottomMargin: 40
            onPrevClicked: usersCycleSelectPrev()
            onNextClicked: usersCycleSelectNext()
        }

        // --- sélection sessions ---
        SessionsChoose {
            id: sessionName
            text: currentSession
            visible: config.boolValue("showSessionsByDefault")
            width: mainFrame.width / 2.5 / 24 * sessionsFontSize
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            onPrevClicked: sessionsCycleSelectPrev()
            onNextClicked: sessionsCycleSelectNext()
        }

        // --- aide (F1) ---
        Text {
            id: helpMessage
            visible: false
            text: "Show help - F1\n" +
                  "Cycle select next user - F2 or Alt+u\n" +
                  "Cycle select previous user - Ctrl+F2 or Alt+Ctrl+u\n" +
                  "Cycle select next session - F3 or Alt+s\n" +
                  "Cycle select previous session - Ctrl+F3 or Alt+Ctrl+s\n" +
                  "Suspend - F10\n" +
                  "Poweroff - F11\n" +
                  "Reboot - F12"
            color: textColor
            font.pointSize: helpFontSize
            font.family: helpFont
            anchors.top: parent.top
            anchors.topMargin: 30
            anchors.left: parent.left
            anchors.leftMargin: 30
        }

        Component.onCompleted: passwordInput.forceActiveFocus()
    }

    // --- cacher le curseur si demandé ---
    Loader {
        active: config.boolValue("hideCursor") || false
        anchors.fill: parent
        sourceComponent: MouseArea {
            enabled: false
            cursorShape: Qt.BlankCursor
        }
    }
}

