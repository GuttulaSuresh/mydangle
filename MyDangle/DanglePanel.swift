import Cocoa

final class DanglePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = true
        backgroundColor = .systemYellow
        hasShadow = true
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = false

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]
    }
}
