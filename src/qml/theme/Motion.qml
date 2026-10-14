pragma Singleton
import QtQuick
import ScanCore

// Motion tokens. Durations collapse to zero when "Reduce motion" is on, so
// every animation in the app respects the setting by using these.
QtObject {
    readonly property bool reduced: App.settings.reducedMotion === true

    readonly property int instant: reduced ? 0 : 90
    readonly property int fast: reduced ? 0 : 150
    readonly property int normal: reduced ? 0 : 240
    readonly property int slow: reduced ? 0 : 380
    readonly property int page: reduced ? 0 : 420
    readonly property int hero: reduced ? 0 : 520

    // Cubic bezier control points for Easing.BezierSpline.
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var emphasized: [0.3, 0, 0, 1, 1, 1]
    readonly property var decelerate: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var spring: [0.34, 1.36, 0.64, 1, 1, 1]

    function stagger(index) {
        return reduced ? 0 : Math.min(index, 16) * 24
    }
}
