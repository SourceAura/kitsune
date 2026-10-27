pragma ComponentBehavior: Bound
/* InseiScene.qml: the scene composition.
 * Top to bottom: hint, the seven-card arc, Ase, the whisper,
 * and InseiHud (entropy bar, lock count, live hash). */

import QtQuick
import QtQuick.Effects
import "../tw" as TW

Item {
    id: root

    property int    lockedCount:     0
    property real   entropy:         0.0
    property bool   hasError:        false
    property bool   isUnlocked:      false
    property bool   isLoading:       false
    property string whisper:         ""
    property string sequenceStr:     ""
    property var    layout:          []
    property var    tappedFolds:     []
    property real   time:            0.0
    property int    activeFoldIdx:   -1
    property color  activeFoldColor: TW.TransparentWorld.accentWater
    property real   activePulse:     0.0
    property real   breach:          0.0
    property bool   setupMode:       false
    property bool   setupPhase2:     false
    property int    resetKey:        0

    signal cardTapped(string foldId, int position, real px, real py)

    readonly property var _foldIds: [
        "truth","power","wisdom","judgment","life","love","discipline"
    ]
    readonly property var _foldLabels: [
        "THE EYE","THE PHANTOM","THE BLADE","THE SAGE","THE SHROUD","THE FORGE","THE MIRROR"
    ]
    readonly property var _foldPrinciples: [
        "TRUTH","POWER","WISDOM","JUDGMENT","LIFE","LOVE","DISCIPLINE"
    ]
    readonly property var _foldColors: [
        "#4ade80","#f43f5e","#00B4D8","#9B1FA0","#818cf8","#f59e0b","#6366f1"
    ]
    readonly property var _foldIcons: [
        "\u25c9","\u2297","\u2694","\u25c8","\u2601","\u2b21","\u25cc"
    ]

    readonly property real _cx: width / 2

    readonly property real _aseW: 320
    readonly property real _aseH: 260
    readonly property real _aseY: height * 0.42

    readonly property real _arcCX: _cx
    readonly property real _arcCY: _aseY + 24
    readonly property real _arcR:  180

    readonly property real _whisperY: _aseY + _aseH + 10
    readonly property real _hudY:     _whisperY + 44

    Text {
        x:       root._cx - implicitWidth / 2
        y:       root._arcCY - root._arcR - 84
        text:    "read the sigils · invoke your sequence"
        opacity: root.lockedCount === 0 && !root.setupMode ? 0.38 : 0.0
        Behavior on opacity { NumberAnimation { duration: 600 } }
        color:          Qt.rgba(1, 1, 1, 1)
        font.family:    TW.TransparentWorld.fontFamilyMono
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Text {
        x:       root._cx - implicitWidth / 2
        y:       root._arcCY - root._arcR - 84
        text:    root.setupPhase2 ? "draw the same sequence to confirm the binding" : "inscribe your sequence across the seven folds"
        opacity: root.setupMode ? 0.38 : 0.0
        Behavior on opacity { NumberAnimation { duration: 600 } }
        color:          Qt.rgba(0.96, 0.74, 0.04, 1)
        font.family:    TW.TransparentWorld.fontFamilyMono
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: 7
            delegate: InseiTarot {
                id: _card
                required property int index

                readonly property var _fold: {
                    if (root.layout.length === 7) return root.layout[index]
                    return { id: root._foldIds[index], color: root._foldColors[index], position: index + 1 }
                }

                readonly property int _ci: {
                    var id = _fold.id || ""
                    for (var i = 0; i < root._foldIds.length; i++)
                        if (root._foldIds[i] === id) return i
                    return index
                }

                readonly property bool _isTapped: root.resetKey >= 0 && root.tappedFolds.indexOf(_fold.id || "") >= 0
                readonly property int  _tapOrder: root.tappedFolds.indexOf(_fold.id || "")

                foldLabel:   root._foldLabels[_ci]
                principle:   root._foldPrinciples[_ci]
                icon:        root._foldIcons[_ci]
                accent:      Qt.color(root._foldColors[_ci])
                position:    _fold.position || (index + 1)
                time:        root.time
                _phase:      index * 0.9

                isRevealed:  _isTapped
                revealOrder: _tapOrder

                readonly property real _spreadDeg: 120.0
                readonly property real _startDeg:  210.0
                readonly property real _stepDeg:   _spreadDeg / 6.0
                readonly property real _angleDeg:  _startDeg + index * _stepDeg
                readonly property real _angleRad:  _angleDeg * Math.PI / 180.0

                x: root._arcCX + root._arcR * Math.cos(_angleRad) - width  / 2
                y: root._arcCY + root._arcR * Math.sin(_angleRad) - height / 2

                rotation: _angleDeg - 270.0

                onTapped: root.cardTapped(_card._fold.id || "", _card._fold.position || (_card.index + 1),
                                           _card.x + _card.width / 2, _card.y + _card.height / 2)
            }
        }
    }

    InseiCompanion {
        id: _ase
        x:      root._cx - implicitWidth  / 2
        y:      root._aseY
        entropy:   root.entropy
        foldColor: root.activeFoldColor
        time:      root.time
    }

    Item {
        x:       root._cx - 200
        y:       root._whisperY
        width:   400
        height:  48
        visible: true
        opacity: root.whisper.length > 0 ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Text {
            anchors.centerIn: parent
            width: parent.width
            text:  root.whisper.toLowerCase()
            color: root.hasError   ? Qt.rgba(0.96, 0.25, 0.37, 0.90)
                 : root.isUnlocked ? Qt.rgba(0.29, 0.87, 0.50, 0.90)
                 : Qt.rgba(0.0, 0.82, 1.0, 0.78)
            font.family:         TW.TransparentWorld.fontFamilyMono
            font.pixelSize:      13
            font.letterSpacing:  1.5
            horizontalAlignment: Text.AlignHCenter
            wrapMode:            Text.WordWrap
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        layer.enabled: root.whisper.length > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurEnabled:   false
            shadowColor: root.hasError
                ? Qt.rgba(0.96, 0.25, 0.37, 0.45)
                : Qt.rgba(0.0, 0.82, 1.0, 0.35)
            shadowBlur:           0.9
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }
    }

    Text {
        x:       root._cx - implicitWidth / 2
        y:       root._whisperY - 20
        visible: root.setupMode
        opacity: root.setupMode ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        text:           root.setupPhase2 ? "confirm" : "setup"
        color:          Qt.rgba(0.96, 0.74, 0.04, 0.70)
        font.family:    TW.TransparentWorld.fontFamilyMono
        font.pixelSize: 9
        font.letterSpacing: 3
    }

    InseiHud {
        x:         root._cx - width / 2
        y:         root._hudY
        width:     320
        entropy:   root.entropy
        locked:    root.lockedCount
        password:  root.sequenceStr
        isLoading: root.isLoading
        time:      root.time
        tappedFolds: root.tappedFolds
    }

    signal castRequested()

    property bool readyToCast: false

    property real _castShatter: 0.0
    NumberAnimation {
        id: _shatterAnim
        target: root; property: "_castShatter"
        from: 0.0; to: 1.0; duration: 600
        easing.type: Easing.OutCubic
        running: false
        onStopped: root._castShatter = 0.0
    }

    readonly property string _castLabel: {
        if (setupMode && setupPhase2) return "CONFIRM THE BINDING"
        if (setupMode)                return "BIND THE SEQUENCE"
        return "INVOKE THE SEAL"
    }

    Item {
        x:       root._cx - 100
        y:       root._aseY - 58
        width:   200
        height:  38
        z:       20
        visible: root.readyToCast && !root.isUnlocked
        opacity: root.readyToCast && !root.isUnlocked ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ShaderEffect {
            anchors.fill: parent
            property real u_time:        root.time
            property real u_confidence:  1.0
            property real u_progress:    root.entropy
            property real u_shatter:     root._castShatter
            property real u_width:       width
            property real u_height:      height
            property real u_morphR:      root.activeFoldColor.r
            property real u_morphG:      root.activeFoldColor.g
            property real u_morphB:      root.activeFoldColor.b
            fragmentShader: "../shaders/crystallize.frag.qsb"
            blending: true
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color:  Qt.rgba(0.02, 0.04, 0.08, 0.85)
            border.width: 1
            border.color: Qt.rgba(root.activeFoldColor.r, root.activeFoldColor.g, root.activeFoldColor.b,
                                  _castHov.hovered ? 0.90 : 0.50)
            Behavior on border.color { ColorAnimation { duration: 120 } }

            SequentialAnimation on border.color {
                loops: Animation.Infinite
                running: root.readyToCast && !root.isUnlocked && !_castHov.hovered
                ColorAnimation { to: Qt.rgba(root.activeFoldColor.r, root.activeFoldColor.g, root.activeFoldColor.b, 0.85); duration: 700; easing.type: Easing.InOutSine }
                ColorAnimation { to: Qt.rgba(root.activeFoldColor.r, root.activeFoldColor.g, root.activeFoldColor.b, 0.28); duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors.centerIn: parent
            z: 2
            text:  root._castLabel
            color: Qt.rgba(1, 1, 1, _castHov.hovered ? 1.0 : 0.92)
            font.family:    TW.TransparentWorld.fontFamilyMono
            font.pixelSize: 12
            font.bold:      true
            font.letterSpacing: 2.5
            Behavior on color { ColorAnimation { duration: 120 } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; blurEnabled: false
                shadowColor:   Qt.rgba(root.activeFoldColor.r, root.activeFoldColor.g, root.activeFoldColor.b, 0.80)
                shadowBlur:    TW.TransparentWorld.shadowBlur
                shadowVerticalOffset: 0; shadowHorizontalOffset: 0
            }
        }

        HoverHandler { id: _castHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: {
                _shatterAnim.restart()
                root.castRequested()
            }
        }
    }

    function aseWake()         { _ase.wake() }
    function aseReact(col)     { _ase.react(col) }
    function aseHurt()         { _ase.hurt() }
    function aseTransform()    { _ase.aseTransform() }
}
