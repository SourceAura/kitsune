pragma Singleton
/* ArOrchestrator.qml: the scene's state singleton, at rest.
 * A lock face has no daemon behind it, so every property the scene
 * can name stands here with quiet values and the face runs in any host. */

import QtQuick

QtObject {
    property real aseWidgetCenterX: 0.5
    property real aseWidgetCenterY: 0.0
    property color prismaticColor: "#bec2ff"
    property int thinkingPhase: 0
    property string scryCommPhase: "idle"
    property string daemonState: "asleep"
    property var aseDrawnFolds: []
    property string intelActiveMode: ""
    property real commandPulse: 0.0
    property real animationPhase: 0.0
    property string breathingStyle: "moon"
    property real shiguruiTokensPerSec: 0.0
    property string aseHubDrawFold: ""
    property string aseHubRecallFold: ""
}
