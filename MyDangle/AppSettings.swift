import Cocoa

final class AppSettings {
    static let shared = AppSettings()

    private enum Key {
        static let isVisible = "isVisible"
        static let anchorFraction = "anchorFraction"
        static let ropeLength = "ropeLength"
        static let charmSize = "charmSize"
        static let damping = "damping"
        static let gravity = "gravity"
        static let charm = "charm"
    }

    private let defaults = UserDefaults.standard

    var isVisible: Bool
    var anchorFraction: CGFloat
    var ropeLength: CGFloat
    var charmSize: CGFloat
    var damping: CGFloat
    var gravity: CGFloat
    var charm: String

    private init() {
        defaults.register(defaults: [
            Key.isVisible: true,
            Key.anchorFraction: 0.50,
            Key.ropeLength: 250.0,
            Key.charmSize: 54.0,
            Key.damping: 0.992,
            Key.gravity: 1200.0,
            Key.charm: "🧿"
        ])

        isVisible = defaults.bool(forKey: Key.isVisible)
        anchorFraction = CGFloat(defaults.double(forKey: Key.anchorFraction))
        ropeLength = CGFloat(defaults.double(forKey: Key.ropeLength))
        charmSize = CGFloat(defaults.double(forKey: Key.charmSize))
        damping = CGFloat(defaults.double(forKey: Key.damping))
        gravity = CGFloat(defaults.double(forKey: Key.gravity))
        charm = defaults.string(forKey: Key.charm) ?? "🧿"
    }

    func save() {
        defaults.set(isVisible, forKey: Key.isVisible)
        defaults.set(Double(anchorFraction), forKey: Key.anchorFraction)
        defaults.set(Double(ropeLength), forKey: Key.ropeLength)
        defaults.set(Double(charmSize), forKey: Key.charmSize)
        defaults.set(Double(damping), forKey: Key.damping)
        defaults.set(Double(gravity), forKey: Key.gravity)
        defaults.set(charm, forKey: Key.charm)
    }

    func reset() {
        isVisible = true
        anchorFraction = 0.50
        ropeLength = 250
        charmSize = 54
        damping = 0.992
        gravity = 1200
        charm = "🧿"
        save()
    }
}
