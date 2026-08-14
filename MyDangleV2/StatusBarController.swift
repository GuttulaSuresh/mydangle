import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let dangleController: DangleController

    init(dangleController: DangleController) {
        self.dangleController = dangleController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        if let button = statusItem.button {
            button.title = "🧿 MyDangle"
            button.toolTip = "MyDangle"
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let toggle = NSMenuItem(
            title: "Show / Hide Dangle",
            action: #selector(toggle),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)

        let push = NSMenuItem(
            title: "Give It a Push",
            action: #selector(pushDangle),
            keyEquivalent: ""
        )
        push.target = self
        menu.addItem(push)

        menu.addItem(.separator())

        let ropeMenu = NSMenu()

        let shortItem = NSMenuItem(title: "Short", action: #selector(shortRope), keyEquivalent: "")
        shortItem.target = self
        ropeMenu.addItem(shortItem)

        let mediumItem = NSMenuItem(title: "Medium", action: #selector(mediumRope), keyEquivalent: "")
        mediumItem.target = self
        ropeMenu.addItem(mediumItem)

        let longItem = NSMenuItem(title: "Long", action: #selector(longRope), keyEquivalent: "")
        longItem.target = self
        ropeMenu.addItem(longItem)

        let ropeRoot = NSMenuItem(title: "Rope Length", action: nil, keyEquivalent: "")
        ropeRoot.submenu = ropeMenu
        menu.addItem(ropeRoot)

        menu.addItem(.separator())

        let reset = NSMenuItem(
            title: "Reset Dangle",
            action: #selector(reset),
            keyEquivalent: ""
        )
        reset.target = self
        menu.addItem(reset)

        let quit = NSMenuItem(
            title: "Quit MyDangle",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    @objc private func toggle() {
        dangleController.toggle()
    }

    @objc private func pushDangle() {
        dangleController.push()
    }

    @objc private func shortRope() {
        dangleController.setRopeLength(180)
    }

    @objc private func mediumRope() {
        dangleController.setRopeLength(240)
    }

    @objc private func longRope() {
        dangleController.setRopeLength(300)
    }

    @objc private func reset() {
        dangleController.reset()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
