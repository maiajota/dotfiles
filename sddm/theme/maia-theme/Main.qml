import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0b0f14"

    property bool useVideo: true

    // Lista de usuários do sistema (preenchida a partir do userModel do SDDM)
    property var userList: []
    property int userIndex: 0
    property string selectedUser: userList.length > 0 ? userList[userIndex].name : ""

    function displayName(u) {
        if (!u)
            return "Usuário"
        return (u.realName && u.realName !== "") ? u.realName : u.name
    }

    function cycleUser(step) {
        if (userList.length < 2)
            return
        userIndex = (userIndex + step + userList.length) % userList.length
        password.text = ""
        loginMessage.text = ""
    }

    // Lista de sessões / interfaces disponíveis (sessionModel do SDDM)
    property var sessionList: []
    property int sessionIndex: 0
    property string selectedSessionName: sessionList.length > 0 ? sessionList[sessionIndex] : ""

    function cycleSession(step) {
        if (sessionList.length < 2)
            return
        sessionIndex = (sessionIndex + step + sessionList.length) % sessionList.length
    }

    Component.onCompleted: {
        var arr = []
        for (var i = 0; i < userModel.count; i++) {
            var idx = userModel.index(i, 0)
            arr.push({
                name: userModel.data(idx, Qt.UserRole + 1) || "",
                realName: userModel.data(idx, Qt.UserRole + 2) || ""
            })
        }
        userList = arr

        // Começa no último usuário que logou
        for (var j = 0; j < arr.length; j++) {
            if (arr[j].name === userModel.lastUser) {
                userIndex = j
                break
            }
        }

        // Sessões (Plasma, niri, ...) a partir do sessionModel
        var sarr = []
        for (var s = 0; s < sessionModel.count; s++) {
            var sidx = sessionModel.index(s, 0)
            var sname = sessionModel.data(sidx, Qt.UserRole + 4)
            sarr.push(sname && sname !== "" ? sname : ("Sessão " + (s + 1)))
        }
        sessionList = sarr
        if (sessionModel.lastIndex >= 0 && sessionModel.lastIndex < sarr.length)
            sessionIndex = sessionModel.lastIndex

        password.forceActiveFocus()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
    }

    Image {
        id: imageBg
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/background.jpeg")
        fillMode: Image.PreserveAspectCrop
        visible: !useVideo
        cache: true
        asynchronous: true
    }

    VideoOutput {
        id: videoBg
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: useVideo
    }

    MediaPlayer {
        id: player
        source: Qt.resolvedUrl("assets/frieren-moon.mp4")
        videoOutput: videoBg
        audioOutput: AudioOutput {
            muted: true
        }
        loops: MediaPlayer.Infinite
        autoPlay: useVideo
    }

    FastBlur {
        anchors.fill: parent
        source: useVideo ? videoBg : imageBg
        radius: useVideo ? 4 : 24
    }

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
    }

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 180
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#99000000" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.rightMargin: 56
        spacing: 4

        Text {
            text: {
                var formatted = Qt.locale("pt_BR").toString(new Date(), "dddd, d 'de' MMMM")
                return formatted.charAt(0).toUpperCase() + formatted.slice(1)
            }
            color: "#b0c7d8"
            font.pixelSize: 18
            font.family: "JetBrains Mono"
        }

        Text {
            id: clockText
            text: Qt.formatTime(new Date(), "hh:mm")
            color: "white"
            font.pixelSize: 68
            font.bold: true
            font.family: "JetBrains Mono"
        }
    }

    Column {
        id: loginArea
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 56
        anchors.bottomMargin: 56
        spacing: 14

        Row {
            spacing: 12

            Text {
                id: userNameText
                text: root.displayName(userList.length > 0 ? userList[userIndex] : null)
                color: "white"
                font.pixelSize: 26
                font.family: "JetBrains Mono"
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: userList.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.cycleUser(1)
                }
            }

            Text {
                visible: userList.length > 1
                anchors.verticalCenter: userNameText.verticalCenter
                text: "‹ " + (userIndex + 1) + "/" + userList.length + " ›"
                color: "#8fb3c7"
                font.pixelSize: 15
                font.family: "JetBrains Mono"

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleUser(1)
                }
            }
        }

        Text {
            visible: {
                var u = userList.length > 0 ? userList[userIndex] : null
                return u && u.realName && u.realName !== "" && u.realName !== u.name
            }
            text: userList.length > 0 ? "@" + userList[userIndex].name : ""
            color: "#7f9bb0"
            font.pixelSize: 13
            font.family: "JetBrains Mono"
        }

        TextField {
            id: password
            width: 280
            height: 40
            echoMode: TextInput.Password
            color: "white"
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            font.letterSpacing: 5
            selectByMouse: true
            padding: 0
            topPadding: 4
            bottomPadding: 10
            // compensa o espaço que o letterSpacing joga antes da 1ª bola
            leftPadding: -2

            // A linha azul é a "borda": vira o sublinhado do campo
            background: Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: password.activeFocus ? "#66d9ff" : "#55aacc"
                opacity: password.activeFocus ? 1.0 : 0.8
            }

            // Setas cima/baixo também trocam o usuário
            Keys.onUpPressed: root.cycleUser(-1)
            Keys.onDownPressed: root.cycleUser(1)

            onAccepted: {
                sddm.login(root.selectedUser, password.text, root.sessionIndex)
            }
        }

        Button {
            id: loginButton
            width: 140
            height: 36
            text: "LOGIN"

            background: Rectangle {
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: loginButton.hovered ? "#66d9ff" : "#55aaccff"
            }

            contentItem: Text {
                text: loginButton.text
                color: "white"
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                sddm.login(root.selectedUser, password.text, root.sessionIndex)
            }
        }

        Text {
            id: loginMessage
            color: "#ff8080"
            font.pixelSize: 12
            font.family: "JetBrains Mono"
            text: ""
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            loginMessage.text = "Usuário ou senha inválidos"
            password.text = ""
        }
    }

    Row {
        id: topControls

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 56
        anchors.topMargin: 48
        spacing: 26

        function txtColor(button) {
            if (button.down)
                return "#66d9ff"
            return button.hovered ? "#eaf4fa" : "#9fb8c8"
        }

        Button {
            id: sessionButton
            padding: 0
            hoverEnabled: true
            visible: sessionList.length > 0
            text: root.selectedSessionName.toUpperCase()
            background: Item {}
            contentItem: Text {
                text: sessionButton.text
                color: topControls.txtColor(sessionButton)
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
            }
            onClicked: root.cycleSession(1)
        }

        Button {
            id: rebootButton
            padding: 0
            hoverEnabled: true
            text: "REINICIAR"
            background: Item {}
            contentItem: Text {
                text: rebootButton.text
                color: topControls.txtColor(rebootButton)
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
            }
            onClicked: sddm.reboot()
        }

        Button {
            id: shutdownButton
            padding: 0
            hoverEnabled: true
            text: "DESLIGAR"
            background: Item {}
            contentItem: Text {
                text: shutdownButton.text
                color: topControls.txtColor(shutdownButton)
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
            }
            onClicked: sddm.powerOff()
        }
    }
}
