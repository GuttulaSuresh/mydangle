import Cocoa

final class AppSettings {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    var ropeLength: CGFloat
    var charmSize: CGFloat
    var anchorFraction: CGFloat
    var isVisible: Bool
    var selectedCharm: String

    // Experimental: asks AppKit to make the dangle window eligible to be
    // visible without login and temporarily raises it to screen-saver level
    // while the user session is inactive. macOS may still hide it behind the
    // secure authentication UI.
    var experimentalLockScreenVisibility: Bool

    private init() {
        defaults.register(defaults: [
            "ropeLength": 235.0,
            "charmSize": 152.0,
            "anchorFraction": 0.50,
            "isVisible": true,
            "selectedCharm": "bhairava",
            "experimentalLockScreenVisibility": false
        ])

        ropeLength = CGFloat(defaults.double(forKey: "ropeLength"))
        charmSize = CGFloat(defaults.double(forKey: "charmSize"))
        anchorFraction = CGFloat(defaults.double(forKey: "anchorFraction"))
        isVisible = defaults.bool(forKey: "isVisible")
        selectedCharm = defaults.string(forKey: "selectedCharm") ?? "bhairava"
        experimentalLockScreenVisibility =
            defaults.bool(forKey: "experimentalLockScreenVisibility")
    }

    func save() {
        defaults.set(Double(ropeLength), forKey: "ropeLength")
        defaults.set(Double(charmSize), forKey: "charmSize")
        defaults.set(Double(anchorFraction), forKey: "anchorFraction")
        defaults.set(isVisible, forKey: "isVisible")
        defaults.set(selectedCharm, forKey: "selectedCharm")
        defaults.set(
            experimentalLockScreenVisibility,
            forKey: "experimentalLockScreenVisibility"
        )
    }

    func reset() {
        ropeLength = 235
        charmSize = 152
        anchorFraction = 0.50
        isVisible = true
        selectedCharm = "bhairava"
        // Keep the experimental lock-screen preference untouched on reset.
        save()
    }
}
