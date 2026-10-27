/* TransparentWorld.qml: design tokens for the lock theme.
 * Only the tokens the lock face and the scene library read:
 * the water accent, the seven fold accents, the style accent
 * map, the mono font stack, and the shadow blur.
 */
pragma Singleton
import QtQuick

QtObject {
    id: theme

    readonly property real shadowBlur: 0.85

    readonly property string fontFamilyMono: "3270 Nerd Font Mono, Fira Code"

    readonly property color accentWater: "#00B4D8"

    // Fold accents
    readonly property color accentEye:       "#00C2FF"
    readonly property color accentBlade:     "#FF3CAC"
    readonly property color accentSage:      "#FFB300"
    readonly property color accentMirror:    "#C8B8FF"
    readonly property color accentPhantom:   "#B44FE8"
    readonly property color accentShroud:    "#00FFC8"
    readonly property color accentForgeFold: "#FF6B35"

    readonly property var styleAccents: ({
        "sun":         "#f59e0b",
        "moon":        "#818cf8",
        "celestial":   "#ffffff",
        "concentrate": "#f59e0b"
    })
}
