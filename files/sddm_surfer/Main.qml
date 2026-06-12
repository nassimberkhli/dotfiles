import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia
import SddmComponents 2.0

Rectangle {
    id: root
    width: 640
    height: 480
    color: config.stringValue("backgroundFill") || "#000000"

    readonly property string defaultFont: config.stringValue("font") || "Homoarakhn"
    readonly property string fallbackFont: config.stringValue("fallbackFont") || "monospace"

    readonly property color textColor: config.stringValue("basicTextColor") || "#ffffff"
    readonly property color secondaryTextColor: config.stringValue("secondaryTextColor") || "#5B5B5B"

    // ── 5 couleurs sémantiques explicites (pilotées par color.sh) ──────────
    readonly property color timeColor:     config.stringValue("timeColor")     || textColor    // l'heure
    readonly property color userColor:     config.stringValue("userColor")     || textColor    // nom user + session
    readonly property color passwordColor: config.stringValue("passwordColor") || textColor    // saisie mot de passe
    readonly property color errorColor:    config.stringValue("errorColor")    || textColor    // message d'erreur
    readonly property color fxColor:       config.stringValue("fxColor")       || textColor    // boutons F1/F2

    // ── 5 polices sémantiques explicites (repli sur defaultFont/fallbackFont) ─
    readonly property string timeFont:     config.stringValue("timeFont")     || defaultFont    // l'heure
    readonly property string userFont:     config.stringValue("userFont")     || defaultFont    // nom user + session
    readonly property string passwordFont: config.stringValue("passwordFont") || defaultFont    // mot de passe
    readonly property string errorFont:    config.stringValue("errorFont")    || defaultFont    // message d'erreur
    readonly property string fxFont:       config.stringValue("fxFont")       || fallbackFont   // boutons F1/F2

    // ── Gradient de la barre mot de passe (min -> max), piloté par color.sh ─
    readonly property color barColorMin: config.stringValue("barColorMin") || "#0000ff"
    readonly property color barColorMid: config.stringValue("barColorMid") || "#00ffaa"
    readonly property color barColorMax: config.stringValue("barColorMax") || "#aaff00"

    property int usernameRole: Qt.UserRole + 1
    property int sessionNameRole: Qt.UserRole + 4

    property int currentUsersIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int currentSessionsIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    property string currentUsername: {
        var value = userModel.data(userModel.index(currentUsersIndex, 0), usernameRole)
        return value || ""
    }

    property string currentSession: {
        var value = sessionModel.data(sessionModel.index(currentSessionsIndex, 0), sessionNameRole)
        return value || ""
    }

    function sourceUrl(path) {
        if (!path || path.length === 0)
            return ""

        if (path.indexOf("file:") === 0 || path.indexOf("qrc:") === 0)
            return path

        if (path[0] === "/")
            return "file://" + path

        return Qt.resolvedUrl(path)
    }

    function isVideo(path) {
        if (!path)
            return false

        return /\.(mp4|webm|mkv|mov|m4v)$/i.test(path) || path.endsWith("/mp4")
    }

    function videoFillMode() {
        switch (config.stringValue("backgroundFillMode")) {
        case "fill":
            return VideoOutput.Stretch
        case "aspect":
        default:
            return VideoOutput.PreserveAspectCrop
        }
    }

    function imageFillMode() {
        switch (config.stringValue("backgroundFillMode")) {
        case "fill":
            return Image.Stretch
        case "tile":
            return Image.Tile
        case "pad":
            return Image.Pad
        case "aspect":
        default:
            return Image.PreserveAspectCrop
        }
    }

    function usersCycleSelectNext() {
        if (userModel.count <= 0)
            return

        currentUsersIndex = currentUsersIndex >= userModel.count - 1 ? 0 : currentUsersIndex + 1
        statusLabel.text = ""
        passwordInput.text = ""
    }

    function usersCycleSelectPrev() {
        if (userModel.count <= 0)
            return

        currentUsersIndex = currentUsersIndex <= 0 ? userModel.count - 1 : currentUsersIndex - 1
        statusLabel.text = ""
        passwordInput.text = ""
    }

    function sessionsCycleSelectNext() {
        var count = sessionModel.rowCount()

        if (count <= 0)
            return

        currentSessionsIndex = currentSessionsIndex >= count - 1 ? 0 : currentSessionsIndex + 1
        statusLabel.text = ""
    }

    function sessionsCycleSelectPrev() {
        var count = sessionModel.rowCount()

        if (count <= 0)
            return

        currentSessionsIndex = currentSessionsIndex <= 0 ? count - 1 : currentSessionsIndex - 1
        statusLabel.text = ""
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            passwordInput.text = ""
            statusLabel.text = "access denied"
            statusLabel.color = errorColor
            failAnimation.restart()
            underlineShake.restart()
        }

        function onLoginSucceeded() {
            statusLabel.text = "opening session"
            statusLabel.color = secondaryTextColor
        }
    }

    Item {
        id: mainFrame
        property variant geometry: screenModel.geometry(screenModel.primary)

        x: geometry.x
        y: geometry.y
        width: geometry.width
        height: geometry.height

        Shortcut {
            sequences: ["Alt+U", "F1"]
            onActivated: usersCycleSelectNext()
        }

        Shortcut {
            sequences: ["Alt+Ctrl+U", "Ctrl+F1"]
            onActivated: usersCycleSelectPrev()
        }

        Shortcut {
            sequences: ["Alt+S", "F2"]
            onActivated: sessionsCycleSelectNext()
        }

        Shortcut {
            sequences: ["Alt+Ctrl+S", "Ctrl+F2"]
            onActivated: sessionsCycleSelectPrev()
        }

        Shortcut {
            sequence: "F3"
            onActivated: {
                if (sddm.canReboot)
                    sddm.reboot()
            }
        }

        Shortcut {
            sequence: "F4"
            onActivated: {
                if (sddm.canPowerOff)
                    sddm.powerOff()
            }
        }

        Shortcut {
            sequence: "F10"
            onActivated: {
                if (sddm.canSuspend)
                    sddm.suspend()
            }
        }

        Shortcut {
            sequence: "F11"
            onActivated: {
                if (sddm.canPowerOff)
                    sddm.powerOff()
            }
        }

        Shortcut {
            sequence: "F12"
            onActivated: {
                if (sddm.canReboot)
                    sddm.reboot()
            }
        }

        Item {
            id: backgroundLayer
            anchors.fill: parent

            property string bg: config.stringValue("background")
            property bool video: isVideo(bg)

            Image {
                anchors.fill: parent
                visible: !backgroundLayer.video
                source: sourceUrl(backgroundLayer.bg)
                fillMode: imageFillMode()
                smooth: true
            }

            MediaPlayer {
                id: player
                source: sourceUrl(backgroundLayer.bg)
                loops: MediaPlayer.Infinite
                autoPlay: backgroundLayer.video
                videoOutput: videoOutput

                audioOutput: AudioOutput {
                    muted: true
                    volume: 0
                }

                onErrorOccurred: function(error, errorString) {
                    console.warn("SDDM background video error:", errorString)
                }
            }

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                visible: backgroundLayer.video
                fillMode: videoFillMode()
            }
        }

        Item {
            id: content
            width: Math.min(480, parent.width * 0.38)
            height: 420

            anchors.left: parent.left
            anchors.leftMargin: Math.max(86, parent.width * 0.075)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: timeLabel
                text: Qt.formatTime(new Date(), "HH:mm")
                color: timeColor

                font.family: timeFont
                font.pointSize: config.intValue("timeFontSize") || 82
                font.bold: false

                anchors.left: parent.left
                anchors.top: parent.top

                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: timeLabel.text = Qt.formatTime(new Date(), "HH:mm")
                }
            }

            Text {
                id: userLabel
                text: currentUsername
                color: userColor
                opacity: 0.92

                font.family: userFont
                font.pointSize: config.intValue("userFontSize") || 22
                font.bold: false

                anchors.left: parent.left
                anchors.top: timeLabel.bottom
                anchors.topMargin: 18

                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering
            }

            Text {
                id: sessionLabel
                visible: config.boolValue("showSession")
                text: currentSession
                color: userColor
                opacity: 0.82

                font.family: userFont
                font.pointSize: config.intValue("sessionFontSize") || 13
                font.bold: false

                anchors.left: parent.left
                anchors.top: userLabel.bottom
                anchors.topMargin: 8

                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering
            }

            Item {
                id: passwordArea
                width: parent.width
                height: 86

                anchors.left: parent.left
                anchors.top: sessionLabel.visible ? sessionLabel.bottom : userLabel.bottom
                anchors.topMargin: 64

                property bool checking: statusLabel.text === "checking"
                property bool failed: statusLabel.text === "access denied"
                property real underlineBaseWidth: 18
                property real underlineActiveWidth: Math.min(passwordInput.width, 28 + passwordInput.text.length * 16)
                property real underlineCheckingWidth: Math.min(passwordInput.width, 160)

                Text {
                    id: passwordPlaceholder
                    visible: passwordInput.text.length === 0
                    text: "password"
                    color: passwordColor
                    opacity: passwordInput.activeFocus ? 0.38 : 0.62

                    font.family: passwordFont
                    font.pointSize: config.intValue("passwordFontSize") || 34
                    font.bold: false

                    anchors.left: parent.left
                    anchors.verticalCenter: passwordInput.verticalCenter

                    renderType: Text.NativeRendering

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                TextInput {
                    id: passwordInput
                    width: Math.min(parent.width * 0.82, 320)
                    height: 64

                    anchors.left: parent.left
                    anchors.top: parent.top

                    focus: true
                    clip: true
                    autoScroll: true

                    leftPadding: 0
                    rightPadding: 0

                    color: passwordColor
                    selectionColor: secondaryTextColor
                    selectedTextColor: "#ffffff"

                    font.family: passwordFont
                    font.pointSize: config.intValue("passwordFontSize") || 34
                    font.bold: false
                    font.letterSpacing: 8

                    horizontalAlignment: TextInput.AlignLeft
                    verticalAlignment: TextInput.AlignVCenter

                    echoMode: config.boolValue("passwordMask") ? TextInput.Password : TextInput.Normal
                    passwordCharacter: config.stringValue("passwordCharacter") || "•"
                    cursorVisible: config.boolValue("passwordInputCursorVisible")

                    onTextEdited: {
                        statusLabel.text = ""
                    }

                    onAccepted: {
                        if (text !== "" || config.boolValue("passwordAllowEmpty")) {
                            statusLabel.text = "checking"
                            statusLabel.color = secondaryTextColor

                            sddm.login(
                                userModel.data(userModel.index(currentUsersIndex, 0), usernameRole),
                                text,
                                currentSessionsIndex
                            )
                        }
                    }
                }

                Rectangle {
                    id: underline
                    height: passwordArea.checking ? 3 : 2
                    radius: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: barColorMin }
                        GradientStop { position: 0.5; color: barColorMid }
                        GradientStop { position: 1.0; color: barColorMax }
                    }

                    width: passwordArea.checking
                        ? passwordArea.underlineCheckingWidth
                        : passwordInput.text.length > 0
                            ? passwordArea.underlineActiveWidth
                            : passwordArea.underlineBaseWidth

                    opacity: passwordArea.checking
                        ? 0.82
                        : passwordInput.text.length > 0
                            ? 0.92
                            : 0.34

                    anchors.left: parent.left
                    anchors.top: passwordInput.bottom
                    anchors.topMargin: 2

                    transform: Translate {
                        id: underlineTranslate
                        x: 0
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: underlineSweep
                    width: 42
                    height: underline.height
                    radius: underline.radius
                    color: textColor
                    opacity: passwordArea.checking ? 0.35 : 0

                    anchors.verticalCenter: underline.verticalCenter
                    x: underline.x

                    SequentialAnimation on x {
                        id: checkingSweep
                        running: passwordArea.checking
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: underline.x
                            to: underline.x + underline.width - underlineSweep.width
                            duration: 720
                            easing.type: Easing.InOutCubic
                        }

                        NumberAnimation {
                            from: underline.x + underline.width - underlineSweep.width
                            to: underline.x
                            duration: 720
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            SequentialAnimation {
                id: underlineShake
                running: false

                NumberAnimation {
                    target: underlineTranslate
                    property: "x"
                    from: 0
                    to: -8
                    duration: 45
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: underlineTranslate
                    property: "x"
                    from: -8
                    to: 8
                    duration: 70
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    target: underlineTranslate
                    property: "x"
                    from: 8
                    to: 0
                    duration: 90
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                id: statusLabel
                text: ""
                color: secondaryTextColor
                opacity: 0.7

                font.family: errorFont
                font.pointSize: config.intValue("statusFontSize") || 13
                font.bold: false

                anchors.left: parent.left
                anchors.top: passwordArea.bottom
                anchors.topMargin: 8

                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering

                SequentialAnimation {
                    id: failAnimation
                    running: false

                    NumberAnimation {
                        target: statusLabel
                        property: "opacity"
                        from: 0.2
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutCubic
                    }

                    PauseAnimation {
                        duration: 950
                    }

                    NumberAnimation {
                        target: statusLabel
                        property: "opacity"
                        from: 1.0
                        to: 0.7
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                id: hintLabel
                text: "F1 user · F2 session · F3 reboot · F4 shutdown"
                color: fxColor
                opacity: 0.72

                font.family: fxFont
                font.pointSize: 10
                font.bold: false

                anchors.left: parent.left
                anchors.bottom: parent.bottom

                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering
            }
        }

        Component.onCompleted: {
            passwordInput.forceActiveFocus()
        }
    }

    Loader {
        active: config.boolValue("hideCursor")
        anchors.fill: parent

        sourceComponent: MouseArea {
            enabled: false
            cursorShape: Qt.BlankCursor
        }
    }
}
