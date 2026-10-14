pragma Singleton
import QtQuick
import ScanCore

// Colour, type and shape tokens. The default palette follows the ScanCore
// website: neutral greys with white (dark) or near-black (light) accents.
QtObject {
    id: theme

    readonly property string mode: App.settings.theme
    readonly property bool dark: mode === "dark" || mode === "black"
        || (mode === "system" && Qt.styleHints.colorScheme !== Qt.ColorScheme.Light)
    readonly property bool black: mode === "black"

    readonly property color bg: black ? "#000000" : dark ? "#0c0c0d" : "#f7f7f8"
    readonly property color sidebar: black ? "#050505" : dark ? "#101012" : "#efeff1"
    readonly property color surface: black ? "#0b0b0b" : dark ? "#151517" : "#ffffff"
    readonly property color surface2: black ? "#141414" : dark ? "#1c1c1f" : "#f1f1f3"
    readonly property color surface3: black ? "#1d1d1d" : dark ? "#26262a" : "#e6e6e9"
    readonly property color border: dark ? "#25252a" : "#e2e2e6"
    readonly property color borderStrong: dark ? "#36363c" : "#cfcfd5"
    readonly property color text: dark ? "#f2f2f3" : "#141416"
    readonly property color textMuted: dark ? "#a3a3ab" : "#5f5f68"
    readonly property color textFaint: dark ? "#6c6c75" : "#94949c"
    readonly property color overlay: dark ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(0.1, 0.1, 0.12, 0.35)
    readonly property color danger: dark ? "#f87171" : "#dc2626"
    readonly property color success: dark ? "#4ade80" : "#16a34a"
    readonly property color warning: dark ? "#fbbf24" : "#d97706"

    // Accent options; "mono" matches the website.
    readonly property var accents: ({
        mono: { dark: "#f2f2f3", light: "#141416", on: { dark: "#0c0c0d", light: "#ffffff" } },
        violet: { dark: "#a78bfa", light: "#7c3aed", on: { dark: "#120a24", light: "#ffffff" } },
        ember: { dark: "#fb923c", light: "#ea580c", on: { dark: "#1f0d02", light: "#ffffff" } },
        sky: { dark: "#38bdf8", light: "#0284c7", on: { dark: "#02131d", light: "#ffffff" } },
        rose: { dark: "#fb7185", light: "#e11d48", on: { dark: "#22050b", light: "#ffffff" } }
    })
    readonly property var accentSet: accents[App.settings.accent] || accents.mono
    readonly property color accent: dark ? accentSet.dark : accentSet.light
    readonly property color onAccent: dark ? accentSet.on.dark : accentSet.on.light

    readonly property string fontSans: "DM Sans"
    readonly property string fontDisplay: "Space Grotesk"
    readonly property string fontSerif: "Literata"

    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int radiusXl: 20

    readonly property int textXs: 11
    readonly property int textSm: 13
    readonly property int textMd: 14
    readonly property int textLg: 16
    readonly property int textXl: 20
    readonly property int text2xl: compact ? 22 : 26
    readonly property int text3xl: compact ? 26 : 34

    // Set by Main.qml: true on phones and very narrow windows.
    property bool compact: false
    readonly property bool touch: App.platform === "android"
    readonly property int gutter: compact ? 16 : 32

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }
}
