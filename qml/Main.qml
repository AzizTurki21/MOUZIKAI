
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    visible: true
    width: 1440
    height: 900
    minimumWidth: 800
    minimumHeight: 650

    title: "MOUZIKAI | Gesture-Powered Music"
    color: "#121212"

    property real clock: 0
    property bool compact: width < 1100
    property bool small: width < 850

    property var gestureNames: ["INDEX", "FIST", "PEACE", "THUMB UP", "OPEN PALM"]
    property var gestureActions: ["Play / Resume", "Pause", "Volume Up", "Volume Down", "Next Track"]
    property var gestureIcons: ["☝", "✊", "✌", "👍", "✋"]

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: window.clock += 0.016
    }

    // =====================================================
    // BACKGROUND
    // =====================================================

    Rectangle {
        anchors.fill: parent
        color: "#121212"
    }

    // Atmospheric moving lights
    Repeater {
        model: 5

        delegate: Rectangle {
            required property int index

            width: 300 + index * 45
            height: width
            radius: width / 2

            x: (Math.sin(window.clock * 0.13 + index * 1.5) + 1)
               * (window.width - width) / 2

            y: (Math.cos(window.clock * 0.11 + index * 2) + 1)
               * (window.height - height) / 2

            color: index % 2 === 0 ? "#18351f" : "#15302a"
            opacity: 0.13

            transform: Rotation {
                origin.x: parent.width / 2
                origin.y: parent.height / 2
                axis.x: 0.3
                axis.y: 1
                axis.z: 0
                angle: Math.sin(window.clock * 0.4 + index) * 35
            }

            SequentialAnimation on scale {
                loops: Animation.Infinite

                NumberAnimation {
                    to: 1.15
                    duration: 4500
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: 0.85
                    duration: 4500
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // Floating particles
    Repeater {
        model: 45

        delegate: Rectangle {
            required property int index

            property real seed: index * 31.73

            width: 3 + index % 4
            height: width
            radius: width / 2

            x: (seed * 17 + window.clock * (5 + index % 7))
               % Math.max(1, window.width)

            y: (seed * 13 + Math.sin(window.clock * 0.4 + seed) * 45)
               % Math.max(1, window.height)

            color: index % 3 === 0 ? "#1DB954" : "#d7ffe4"

            opacity: 0.12 + 0.28 * (
                0.5 + 0.5 * Math.sin(window.clock * 2 + seed)
            )
        }
    }

    // Floating translucent objects
    Repeater {
        model: 4

        delegate: Rectangle {
            required property int index

            width: 48 + index * 12
            height: width
            radius: index % 2 === 0 ? width / 2 : 12

            x: window.width * (0.12 + index * 0.22)
               + Math.sin(window.clock * 0.5 + index) * 35

            y: window.height * 0.48
               + Math.cos(window.clock * 0.35 + index * 2) * 115

            rotation: window.clock * (index % 2 === 0 ? 18 : -15)
                      + index * 40

            color: "#1DB954"
            opacity: 0.055

            border.color: "#7affad"
            border.width: 1

            scale: 0.85 + 0.15 * Math.sin(window.clock * 0.6 + index)
        }
    }

    // =====================================================
    // FLICKABLE DASHBOARD
    // =====================================================

    Flickable {
        id: flick

        anchors.fill: parent

        anchors.leftMargin: window.small ? 12 : 28
        anchors.rightMargin: window.small ? 18 : 30
        anchors.topMargin: 20
        anchors.bottomMargin: 18

        clip: true

        contentWidth: width
        contentHeight: dashboard.implicitHeight + 24

        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: ScrollBar {
            id: verticalBar
            policy: ScrollBar.AlwaysOff
            parent: flick
            x: flick.width - width
            y: 0
            height: flick.height

            width: 7

            background: Rectangle {
                color: "transparent"
            }

            contentItem: Rectangle {
                radius: 4
                color: "#1DB954"
                opacity: verticalBar.pressed ? 1 : 0.55
            }
        }

        ColumnLayout {
            id: dashboard

            width: flick.width
            spacing: 20

            // =================================================
            // HEADER
            // =================================================

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                spacing: 16

                RowLayout {
                    spacing: 1

                    Text {
                        text: "MOUZIK"
                        color: "#ffffff"
                        font.pixelSize: window.small ? 24 : 30
                        font.bold: true
                    }

                    Text {
                        text: "AI"
                        color: "#1DB954"
                        font.pixelSize: window.small ? 24 : 30
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "GESTURE-POWERED MUSIC"
                        color: "#eeeeee"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        text: "COMPUTER VISION / HUMAN-COMPUTER INTERACTION"
                        color: "#888888"
                        font.pixelSize: 8
                    }
                }

                SpotifyButton {
                    text: music.cameraRunning ? "STOP CAMERA" : "START CAMERA"

                    onClicked: music.toggleCamera()
                }
            }

            // =================================================
            // DASHBOARD GRID
            // =================================================

            GridLayout {
                Layout.fillWidth: true

                columns: window.compact ? 1 : 2
                columnSpacing: 18
                rowSpacing: 18

                // LEFT SIDE
                ColumnLayout {
                    Layout.fillWidth: true

                    Layout.preferredWidth: window.compact
                        ? flick.width
                        : flick.width * 0.61

                    spacing: 18

                    // LIVE CAMERA
                    SpotifyPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 410

                        title: "LIVE HAND TRACKING"

                        trailing: music.cameraRunning
                            ? "● CAMERA ACTIVE"
                            : "● CAMERA OFFLINE"

                        trailingColor: music.cameraRunning
                            ? "#1DB954" : "#e6a15c"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 14

                            radius: 15
                            color: "#090909"
                            border.color: "#333333"
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2

                                source: "image://camera/live?"
                                        + music.frameRevision

                                fillMode: Image.PreserveAspectFit
                                cache: false
                                visible: music.cameraRunning
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 13

                                visible: !music.cameraRunning

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "✋"
                                    font.pixelSize: 65
                                    color: "#1DB954"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Your gesture stage is waiting"

                                    color: "white"
                                    font.pixelSize: 17
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Start the camera to begin hand tracking"

                                    color: "#999999"
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 12

                                visible: music.cameraRunning

                                color: "#cc101010"
                                radius: 10
                                width: 105
                                height: 27

                                Text {
                                    anchors.centerIn: parent
                                    text: "● LIVE"
                                    color: "#1DB954"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // GESTURE CARDS
                    SpotifyPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220

                        title: "GESTURE CONTROLS"
                        trailing: "CONTROL MUSIC WITH YOUR HAND"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Repeater {
                                model: 5

                                delegate: GestureCard {
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    iconText: window.gestureIcons[index]
                                    name: window.gestureNames[index]
                                    action: window.gestureActions[index]

                                    active: music.gesture
                                        === window.gestureNames[index]
                                }
                            }
                        }
                    }

                    // GESTURE STATUS
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 53

                        radius: 12
                        color: "#202020"
                        border.color: "#343434"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            Text {
                                text: "GESTURE RECOGNITION"
                                color: "#999999"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                text: music.gesture
                                color: "#1DB954"
                                font.pixelSize: 12
                                font.bold: true

                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "ON-DEVICE"
                                color: "#1DB954"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }

                // RIGHT SIDE
                ColumnLayout {
                    Layout.fillWidth: true

                    Layout.preferredWidth: window.compact
                        ? flick.width
                        : flick.width * 0.39

                    spacing: 18

                    // NOW PLAYING
                    SpotifyPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 255

                        title: "NOW PLAYING"
                        trailing: "GESTURE CONTROLLED"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 22

                            Vinyl {
                                Layout.preferredWidth: window.small ? 95 : 125
                                Layout.preferredHeight: window.small ? 95 : 125

                                spinning: music.playing
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 9

                                Text {
                                    text: music.currentTrack
                                    color: "white"
                                    font.pixelSize: 18
                                    font.bold: true

                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: music.playing
                                        ? "NOW PLAYING"
                                        : "READY WHEN YOU ARE"

                                    color: music.playing ? "#1DB954" : "#999999"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                Text {
                                    text: "CONTROL WITH YOUR HAND"
                                    color: "#999999"
                                    font.pixelSize: 8
                                    font.bold: true
                                }

                                Row {
                                    spacing: 3

                                    Repeater {
                                        model: 22

                                        delegate: Rectangle {
                                            required property int index

                                            width: 4

                                            height: music.playing
                                                ? 6 + 20 * (
                                                    0.5 + 0.5 * Math.sin(
                                                        window.clock * 5
                                                        + index * 0.7
                                                    )
                                                )
                                                : 6

                                            radius: 2
                                            color: "#1DB954"

                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: 120
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // MUSIC LIBRARY
                    SpotifyPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280

                        title: "YOUR MUSIC"
                        trailing: "LOCAL LIBRARY"

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 10

                            clip: true
                            spacing: 6
                            model: music.tracks

                            delegate: Rectangle {
                                required property int index
                                required property string modelData

                                width: ListView.view.width
                                height: 47
                                radius: 9

                                color: music.currentTrack === modelData
                                    ? "#244b34" : "#242424"

                                border.color: music.currentTrack === modelData
                                    ? "#1DB954" : "#333333"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text {
                                        text: "♫"
                                        color: "#1DB954"
                                        font.pixelSize: 17
                                    }

                                    Text {
                                        text: modelData
                                        color: "white"
                                        font.pixelSize: 12
                                        font.bold: true

                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: music.currentTrack === modelData
                                            ? "PLAYING" : "•••"

                                        color: "#1DB954"
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {
                                        music.selectTrack(index)
                                        music.play()
                                    }
                                }
                            }
                        }
                    }

                    // VOLUME
                    SpotifyPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 115

                        title: "VOLUME"
                        trailing: Math.round(music.volume * 100) + "%"

                        Slider {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            from: 0
                            to: 1
                            value: music.volume

                            onMoved: music.setVolume(value)

                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding
                                   + parent.availableHeight / 2 - height / 2

                                width: parent.availableWidth
                                height: 5
                                radius: 3
                                color: "#505050"

                                Rectangle {
                                    width: parent.width
                                        * parent.parent.visualPosition

                                    height: parent.height
                                    radius: 3
                                    color: "#1DB954"
                                }
                            }

                            handle: Rectangle {
                                x: parent.leftPadding
                                   + parent.visualPosition
                                   * (parent.availableWidth - width)

                                y: parent.topPadding
                                   + parent.availableHeight / 2 - height / 2

                                width: 17
                                height: 17
                                radius: 9

                                color: "white"
                                border.color: "#1DB954"
                                border.width: 3
                            }
                        }
                    }
                }
            }

            // FOOTER
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "MOUZIKAI / COMPUTER VISION / HUMAN-COMPUTER INTERACTION"
                    color: "#777777"
                    font.pixelSize: 8
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "© 2026 MAT"
                    color: "#1DB954"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }
    }

    // =====================================================
    // ERROR DIALOG
    // =====================================================

    Connections {
        target: music

        function onErrorRaised(message) {
            errorDialog.text = message
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog

        property alias text: errorText.text

        anchors.centerIn: parent
        modal: true
        title: "MOUZIKAI"
        standardButtons: Dialog.Ok

        background: Rectangle {
            color: "#242424"
            radius: 14
            border.color: "#1DB954"
        }

        contentItem: Text {
            id: errorText
            color: "white"
            wrapMode: Text.WordWrap
            padding: 12
        }
    }

    onClosing: music.shutdown()

    // =====================================================
    // REUSABLE COMPONENTS
    // =====================================================

    component SpotifyPanel: Rectangle {
        property string title: ""
        property string trailing: ""
        property color trailingColor: "#aaaaaa"

        default property alias content: contentArea.data

        radius: 16
        color: "#181818"
        border.color: "#333333"
        border.width: 1
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: 48
            radius: 16
            color: "#202020"
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.leftMargin: 15
            anchors.rightMargin: 15
            height: 48

            Text {
                text: parent.parent.title
                color: "white"
                font.pixelSize: 11
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: parent.parent.trailing
                color: parent.parent.trailingColor
                font.pixelSize: 8
                font.bold: true
            }
        }

        Item {
            id: contentArea

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            anchors.topMargin: 49
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
        }
    }

    // Completely custom button:
    // no Qt default background or hover mask.
    component SpotifyButton: Rectangle {
        id: customButton

        property string text: ""

        signal clicked()

        implicitWidth: 155
        implicitHeight: 46

        radius: height / 2

        color: mouseArea.pressed
            ? "#168b40"
            : mouseArea.containsMouse
                ? "#21d760"
                : "#1DB954"

        scale: mouseArea.pressed
            ? 0.96
            : mouseArea.containsMouse
                ? 1.055
                : 1.0

        transformOrigin: Item.Center

        border.width: mouseArea.containsMouse ? 1.5 : 1
        border.color: mouseArea.containsMouse
            ? "#a0ffc0" : "#1DB954"

        Behavior on scale {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutBack
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 220
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 220
            }
        }

        Text {
            anchors.centerIn: parent

            text: customButton.text
            color: "#ffffff"

            font.pixelSize: 11
            font.bold: true
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: customButton.clicked()
        }
    }

    // Gesture cards
    component GestureCard: Rectangle {
        property string iconText: ""
        property string name: ""
        property string action: ""
        property bool active: false

        radius: 12

        color: active ? "#244b34" : "#242424"

        border.color: active ? "#1DB954" : "#414141"
        border.width: active ? 2 : 1

        scale: active ? 1.04 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 160
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 160
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: iconText
                color: "#1DB954"
                font.pixelSize: 28
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: name
                color: "white"
                font.pixelSize: 9
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: action
                color: "#aaaaaa"
                font.pixelSize: 8
            }
        }
    }

    // Animated vinyl record
    component Vinyl: Item {
        property bool spinning: false

        Rectangle {
            id: vinylBody

            anchors.fill: parent

            radius: width / 2
            color: "#080808"

            border.color: "#1DB954"
            border.width: 2

            Repeater {
                model: 5

                delegate: Rectangle {
                    required property int index

                    anchors.centerIn: parent

                    width: parent.width * (0.85 - index * 0.13)
                    height: width
                    radius: width / 2

                    color: "transparent"
                    border.color: "#393939"
                    border.width: 2
                }
            }

            Rectangle {
                anchors.centerIn: parent

                width: parent.width * 0.31
                height: width
                radius: width / 2

                color: "#1DB954"

                Text {
                    anchors.centerIn: parent

                    text: "M"
                    color: "white"
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            RotationAnimation on rotation {
                running: spinning

                from: 0
                to: 360
                duration: 5000
                loops: Animation.Infinite
            }

            transform: Rotation {
                origin.x: vinylBody.width / 2
                origin.y: vinylBody.height / 2

                axis.x: 1
                axis.y: 0
                axis.z: 0

                angle: 12 + Math.sin(window.clock * 0.7) * 5
            }
        }
    }
}
