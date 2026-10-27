/* InseiCompanion.qml: Ase, the seven-tailed fox, as an SDF shader.
 * The item is 280x320 so the tails and aura have room in the UV space.
 * Each tail tip is tinted with its fold colour. */

import QtQuick
import "../tw" as TW

Item {
    id: root

    implicitWidth:  320
    implicitHeight: 260

    property color foldColor: TW.TransparentWorld.accentWater
    property real  entropy:   0.0
    property real  time:      0.0

    property string _state: "idle"

    function wake()         { _state = "wake";      wakeAnim.restart() }
    function react(col)     { foldColor = col; _state = "react"; reactAnim.restart() }
    function hurt()         { _state = "hurt";      hurtAnim.restart() }
    function aseTransform() { _state = "transform"; transformAnim.restart() }
    function dissolve()     { _state = "dissolve";  dissolveAnim.restart() }
    function resetIdle()    { _state = "idle" }

    ShaderEffect {
        anchors.fill: parent
        blending: true

        property real time:       root.time
        property real entropy:    root.entropy
        property real mood_joy:   0.0
        property real mood_sad:   0.0
        property real mood_sleep: 0.0
        property real fold_r:     root.foldColor.r
        property real fold_g:     root.foldColor.g
        property real fold_b:     root.foldColor.b
        property real w:          width
        property real h:          height
        property real tailCount:  7.0

        property real tail0_r: TW.TransparentWorld.accentEye.r
        property real tail0_g: TW.TransparentWorld.accentEye.g
        property real tail0_b: TW.TransparentWorld.accentEye.b
        property real tail1_r: TW.TransparentWorld.accentPhantom.r
        property real tail1_g: TW.TransparentWorld.accentPhantom.g
        property real tail1_b: TW.TransparentWorld.accentPhantom.b
        property real tail2_r: TW.TransparentWorld.accentBlade.r
        property real tail2_g: TW.TransparentWorld.accentBlade.g
        property real tail2_b: TW.TransparentWorld.accentBlade.b
        property real tail3_r: TW.TransparentWorld.accentSage.r
        property real tail3_g: TW.TransparentWorld.accentSage.g
        property real tail3_b: TW.TransparentWorld.accentSage.b
        property real tail4_r: TW.TransparentWorld.accentShroud.r
        property real tail4_g: TW.TransparentWorld.accentShroud.g
        property real tail4_b: TW.TransparentWorld.accentShroud.b
        property real tail5_r: TW.TransparentWorld.accentForgeFold.r
        property real tail5_g: TW.TransparentWorld.accentForgeFold.g
        property real tail5_b: TW.TransparentWorld.accentForgeFold.b
        property real tail6_r: TW.TransparentWorld.accentMirror.r
        property real tail6_g: TW.TransparentWorld.accentMirror.g
        property real tail6_b: TW.TransparentWorld.accentMirror.b

        fragmentShader: "../shaders/InseiKitsune.frag.qsb"
    }

    TapHandler {
        onTapped: {
            var req = new XMLHttpRequest()
            req.open("POST", "http://127.0.0.1:8001/api/ase/interact", true)
            req.setRequestHeader("Content-Type", "application/json")
            req.send(JSON.stringify({ action: "stroke" }))
            root.react(TW.TransparentWorld.accentWater)
        }
    }

    SequentialAnimation {
        id: wakeAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 1000 }
        ScriptAction    { script: root._state = "idle" }
    }

    SequentialAnimation {
        id: reactAnim
        NumberAnimation { target: root; property: "entropy"; to: 0.8; duration: 200 }
        NumberAnimation { target: root; property: "entropy"; to: 0.0; duration: 400 }
        ScriptAction    { script: root._state = "idle" }
    }

    SequentialAnimation {
        id: hurtAnim
        NumberAnimation { target: root; property: "entropy"; to: 1.0; duration: 80  }
        NumberAnimation { target: root; property: "entropy"; to: 0.0; duration: 600 }
        ScriptAction    { script: root._state = "idle" }
    }

    SequentialAnimation {
        id: transformAnim
        PauseAnimation { duration: 1000 }
        ScriptAction   { script: root.dissolve() }
    }

    SequentialAnimation {
        id: dissolveAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 800 }
    }
}
