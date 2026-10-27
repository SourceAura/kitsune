/* Main.qml: preserved record of the lock face as first built.
 * Not installed. content/Main.qml is the shipped face for both doors. */

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "gotchi"

Item {
    id: root

    property var gate: null
    property var screen: null

    readonly property bool active: !!(root.gate && root.screen && root.gate.active === root.screen.name)

    function focusField() { field.forceActiveFocus(); }

    property color palBackground: "#12131c"
    property color palText:       "#e3e1ef"
    property color palPrimary:    "#bec2ff"
    property color palSecondary:  "#ccc1e9"
    property color palAlert:      "#f43f5e"

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/jurai/generated/palette.json"
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._applyPalette()
    }
    function _applyPalette() {
        try {
            const p = JSON.parse(paletteFile.text());
            if (p.background) root.palBackground = p.background;
            if (p.text)       root.palText = p.text;
            if (p.primary)    root.palPrimary = p.primary;
            if (p.secondary)  root.palSecondary = p.secondary;
            if (p.alert)      root.palAlert = p.alert;
        } catch (e) {    }
    }

    readonly property var _foldIds: ["truth","power","wisdom","judgment","life","love","discipline"]
    readonly property var _foldLabels: ["THE EYE","THE PHANTOM","THE BLADE","THE SAGE","THE SHROUD","THE FORGE","THE MIRROR"]
    readonly property var _foldPrinciples: ["TRUTH","POWER","WISDOM","JUDGMENT","LIFE","LOVE","DISCIPLINE"]
    readonly property var _foldColors: ["#4ade80","#f43f5e","#00B4D8","#9B1FA0","#818cf8","#f59e0b","#6366f1"]

    readonly property string _pw: root.gate ? root.gate.password : ""
    readonly property int _bound: Math.min(7, root._pw.length)

    property var    _tapped: []
    property int    _activeFoldIdx: -1
    property color  _activeFoldColor: "#00B4D8"
    property real   _activePulse: 0.0
    property int    _lastLen: 0

    NumberAnimation {
        id: pulseDecay
        target: root; property: "_activePulse"
        to: 0.0; duration: 500; easing.type: Easing.OutCubic
        running: false
    }

    readonly property real _entropy: {
        const pw = root._pw;
        if (pw.length === 0) return 0;
        const uniq = new Set(pw.split("")).size;
        const lenScore = Math.min(1, pw.length / 16);
        const variety = uniq / pw.length;
        return Math.min(1, lenScore * 0.65 + variety * 0.25 + lenScore * variety * 0.3);
    }

    property string _whisperTarget: ""
    property string _whisperDisplay: ""
    property int    _whisperIdx: 0

    function _setWhisper(msg) {
        root._whisperTarget = msg;
        root._whisperDisplay = "";
        root._whisperIdx = 0;
        whisperTimer.restart();
    }
    Timer {
        id: whisperTimer; interval: 22; repeat: true
        onTriggered: {
            if (root._whisperIdx < root._whisperTarget.length) {
                root._whisperDisplay += root._whisperTarget[root._whisperIdx];
                root._whisperIdx++;
            } else { stop(); }
        }
    }

    property real _time: 0.0
    NumberAnimation on _time {
        from: 0; to: 100000; duration: 100000000
        loops: Animation.Infinite; running: true
    }

    Image {
        anchors.fill: parent
        source: root.gate && root.screen ? root.gate.wallpaperFor(root.screen.name) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.gate && root.gate.leaving ? 0.3 : 0.9
            blurMax: 64
            brightness: root.gate && root.gate.leaving ? -0.05 : -0.25
            Behavior on blur { NumberAnimation { duration: 380; easing.type: Easing.OutQuad } }
            Behavior on brightness { NumberAnimation { duration: 380; easing.type: Easing.OutQuad } }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(root.palBackground, 0.55)
    }

    InseiScene {
        id: scene
        anchors.fill: parent

        layout:          []
        tappedFolds:     root._tapped
        lockedCount:     root._bound
        entropy:         root._entropy
        sequenceStr:     root._tapped.join(":")
        time:            root._time
        activeFoldIdx:   root._activeFoldIdx
        activeFoldColor: root._activeFoldColor
        activePulse:     root._activePulse
        whisper:         root._whisperDisplay
        hasError:        !!(root.gate && root.gate.failed)
        isLoading:       !!(root.gate && root.gate.checking)
        isUnlocked:      !!(root.gate && root.gate.leaving)
        readyToCast:     root._bound >= 7 && !!root.gate && !root.gate.checking && !root.gate.leaving

        onCastRequested: if (root.gate) root.gate.submit()
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 54
        spacing: 12
        z: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.active && !!root.gate && root.gate.failed
            text: root.gate ? root.gate.reason : ""
            color: root.palAlert
            font.family: "3270 Nerd Font Mono, Fira Code, monospace"
            font.pixelSize: 12
            font.letterSpacing: 2
        }

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.active
            width: 300
            height: 46
            radius: 23
            color: Qt.alpha("#0a0a12", 0.55)
            border.width: 1
            border.color: root.gate && root.gate.failed
                ? Qt.alpha(root.palAlert, 0.8)
                : (field.activeFocus ? Qt.alpha(root.palPrimary, 0.6) : Qt.alpha(root.palText, 0.22))
            Behavior on border.color { ColorAnimation { duration: 200 } }
            transform: Translate { id: pillShift }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: pillShift; property: "x"; to: -7; duration: 45 }
                NumberAnimation { target: pillShift; property: "x"; to: 6; duration: 55 }
                NumberAnimation { target: pillShift; property: "x"; to: -4; duration: 55 }
                NumberAnimation { target: pillShift; property: "x"; to: 2; duration: 50 }
                NumberAnimation { target: pillShift; property: "x"; to: 0; duration: 45 }
            }
            opacity: root.gate && root.gate.leaving ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 300 } }

            TextField {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                echoMode: TextInput.Password
                placeholderText: "PASSWORD"
                placeholderTextColor: Qt.alpha(root.palText, 0.35)
                color: root.palText
                font.family: "3270 Nerd Font Mono, Fira Code, monospace"
                font.pixelSize: 14
                font.letterSpacing: 2
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                background: Item {}
                enabled: !(root.gate && root.gate.checking)
                onTextEdited: if (root.gate) root.gate.password = text
                onAccepted: if (root.gate) root.gate.submit()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !!root.gate
            text: "0XSRCAURA"
            color: Qt.alpha(root.palText, 0.55)
            opacity: root.gate && root.gate.leaving ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
            font.family: "3270 Nerd Font Mono, Fira Code, monospace"
            font.pixelSize: 13
            font.letterSpacing: 4
        }
    }

    Timer {
        id: manifestTimer; interval: 60; repeat: false
        onTriggered: {
            scene.aseWake();
            root._setWhisper("the sigils await · read the cards · invoke your sequence");
        }
    }
    Component.onCompleted: manifestTimer.restart()

    Connections {
        target: root.gate

        function onPasswordChanged() {
            const n = root._pw.length;
            const bound = Math.min(7, n);
            if (root.gate.leaving) return;

            if (n > root._lastLen && bound > 0) {
                const ci = bound - 1;
                root._activeFoldIdx = ci;
                root._activeFoldColor = root._foldColors[ci];
                root._activePulse = 1.0;
                pulseDecay.restart();
                scene.aseReact(Qt.color(root._foldColors[ci]));
            }
            root._lastLen = n;
            root._tapped = root._foldIds.slice(0, bound);

            if (root.gate.failed || root.gate.checking) return;
            if (bound === 0)
                root._setWhisper("the sigils await · read the cards · invoke your sequence");
            else if (bound < 7)
                root._setWhisper(root._foldLabels[bound - 1] + " · " + root._foldPrinciples[bound - 1] + " · bound to your will · " + bound + " of 7");
            else
                root._setWhisper("the sequence is complete · invoke the seal to pass");
        }

        function onCheckingChanged() {
            if (root.gate.checking)
                root._setWhisper("the binding speaks · the seal yields…");
        }

        function onFailedChanged() {
            if (root.gate.failed) {
                scene.aseHurt();
                shake.restart();
                field.text = "";
                if (root.gate) root.gate.password = "";
                root._lastLen = 0;
                root._tapped = [];
                failWhisper.restart();
                field.forceActiveFocus();
            }
        }

        function onLeavingChanged() {
            if (root.gate.leaving) {
                root._tapped = root._foldIds.slice(0, 7);
                scene.aseTransform();
                root._setWhisper("the seal opens · welcome, 0xSrcAura");
            }
        }
    }

    Timer {
        id: failWhisper; interval: 150; repeat: false
        onTriggered: root._setWhisper(root.gate ? root.gate.reason : "the binding refuses")
    }
}
