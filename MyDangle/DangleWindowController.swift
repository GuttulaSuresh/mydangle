import Cocoa

final class DangleWindowController {

    private let settings: AppSettings
    private var panel: NSWindow?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func show() {
        print("🟡 Creating MyDangle test window")

        let frame = NSRect(
            x: 300,
            y: 400,
            width: 500,
            height: 300
        )

        let newPanel = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        newPanel.title = "MyDangle Test"
        newPanel.backgroundColor = .systemYellow

        let label = NSTextField(labelWithString: "🧿 MYDANGLE TEST")

        label.font = NSFont.systemFont(
            ofSize: 36,
            weight: .bold
        )

        label.textColor = .black
        label.alignment = .center

        label.frame = NSRect(
            x: 20,
            y: 110,
            width: 460,
            height: 60
        )

        let container = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 500,
                height: 300
            )
        )

        container.wantsLayer = true
        container.layer?.backgroundColor =
            NSColor.systemYellow.cgColor

        container.addSubview(label)

        newPanel.contentView = container

        newPanel.makeKeyAndOrderFront(nil)
        newPanel.orderFrontRegardless()

        panel = newPanel

        print("✅ Yellow test window displayed")
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func kick() {
    }

    func resetPhysics() {
    }

    func refreshLayout() {
    }

    func setHorizontalPosition(_ fraction: CGFloat) {
    }

    func rebuild() {
        panel?.close()
        panel = nil
        show()
    }
}
