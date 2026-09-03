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

        ComboBox {
            id: userSelector
            visible: false

            model: userModel
            currentIndex: userModel.lastIndex >= 0
                          ? userModel.lastIndex
                          : 0
            textRole: "name"
        }

        Text {
            text: userSelector.currentText !== ""
                  ? userSelector.currentText
                  : "Usuário"
            color: "white"
            font.pixelSize: 26
            font.family: "JetBrains Mono"
            font.bold: true
        }

        Rectangle {
            width: 280
            height: 2
            color: "#55aacc"
            opacity: 0.8
        }

        TextField {
            id: username
            visible: false
            text: userSelector.currentText
        }

        TextField {
            id: password
            width: 280
            height: 46
            placeholderText: "Senha"
            echoMode: TextInput.Password
            color: "white"
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            selectByMouse: true

            background: Rectangle {
                radius: 8
                color: "#14000000"
                border.width: 1
                border.color: password.activeFocus ? "#66d9ff" : "#55aaccff"
            }

            onAccepted: {
                sddm.login(username.text, password.text, sessionModel.index)
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
                sddm.login(username.text, password.text, sessionModel.index)
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
        id: bottomControls

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 56
        anchors.bottomMargin: 56
        spacing: 12

        function glassColor(button) {
            if (button.down)
                return "#35ffffff"
                if (button.hovered)
                    return "#25ffffff"
                    return "#18ffffff"
        }

        Button {
            id: rebootButton
            width: 135
            height: 48
            hoverEnabled: true
            text: "Reiniciar"

            background: Rectangle {
                radius: 12
                color: bottomControls.glassColor(rebootButton)
                border.width: 1
                border.color: "#40ffffff"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 11
                    color: "transparent"
                    border.width: 1
                    border.color: "#10ffffff"
                }
            }

            contentItem: Text {
                text: rebootButton.text
                color: "white"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                leftPadding: 20
                rightPadding: 20
                topPadding: 10
                bottomPadding: 10
            }

            onClicked: sddm.reboot()
        }

        Button {
            id: shutdownButton
            width: 135
            height: 48
            hoverEnabled: true
            text: "Desligar"

            background: Rectangle {
                radius: 12
                color: bottomControls.glassColor(shutdownButton)
                border.width: 1
                border.color: "#40ffffff"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 11
                    color: "transparent"
                    border.width: 1
                    border.color: "#10ffffff"
                }
            }

            contentItem: Text {
                text: shutdownButton.text
                color: "white"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                leftPadding: 20
                rightPadding: 20
                topPadding: 10
                bottomPadding: 10
            }

            onClicked: sddm.powerOff()
        }
    }
}
