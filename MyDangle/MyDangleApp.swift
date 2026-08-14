import Cocoa

@main
final class MyDangleApp: NSObject, NSApplicationDelegate {

    private var testWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {

        NSApp.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 600,
                height: 400
            ),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "MyDangle Test"
        window.backgroundColor = .systemYellow
        window.center()

        let label = NSTextField(labelWithString: "🧿 MYDANGLE IS WORKING!")

        label.font = NSFont.systemFont(
            ofSize: 36,
            weight: .bold
        )

        label.alignment = .center

        label.frame = NSRect(
            x: 40,
            y: 160,
            width: 520,
            height: 70
        )

        window.contentView?.addSubview(label)

        self.testWindow = window

        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}
