import Cocoa

final class AppSettings {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    var ropeLength: CGFloat
    var charmSize: CGFloat
    var anchorFraction: CGFloat
    var isVisible: Bool
    var selectedCharm: String

    private init() {
        defaults.register(defaults: [
            "ropeLength": 235.0,
            "charmSize": 152.0,
            "anchorFraction": 0.50,
            "isVisible": true,
            "selectedCharm": "bhairava"
        ])
        ropeLength = CGFloat(defaults.double(forKey: "ropeLength"))
        charmSize = CGFloat(defaults.double(forKey: "charmSize"))
        anchorFraction = CGFloat(defaults.double(forKey: "anchorFraction"))
        isVisible = defaults.bool(forKey: "isVisible")
        selectedCharm = defaults.string(forKey: "selectedCharm") ?? "bhairava"
    }

    func save() {
        defaults.set(Double(ropeLength), forKey: "ropeLength")
        defaults.set(Double(charmSize), forKey: "charmSize")
        defaults.set(Double(anchorFraction), forKey: "anchorFraction")
        defaults.set(isVisible, forKey: "isVisible")
        defaults.set(selectedCharm, forKey: "selectedCharm")
    }

    func reset() {
        ropeLength = 235; charmSize = 152; anchorFraction = 0.50
        isVisible = true; selectedCharm = "bhairava"; save()
    }
}
