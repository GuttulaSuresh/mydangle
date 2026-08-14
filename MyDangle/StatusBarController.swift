import Cocoa

final class StatusBarController: NSObject {
    private let settings: AppSettings
    private let dangleController: DangleController
    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    init(settings: AppSettings, dangleController: DangleController) {
        self.settings = settings
        self.dangleController = dangleController
        super.init()

        if let button = statusItem.button {
            button.title = "🪬 MyDangle"
            button.toolTip = "MyDangle 1.5"
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let physicsTitle = NSMenuItem(
            title: "Physics v1.5",
            action: nil,
            keyEquivalent: ""
        )
        physicsTitle.isEnabled = false
        menu.addItem(physicsTitle)

        let charmRoot = NSMenuItem(
            title: "Charm",
            action: nil,
            keyEquivalent: ""
        )
        let charmMenu = NSMenu()
        addCharm("Bhairava", "bhairava", to: charmMenu)
        addCharm("Lemon & Chilli", "lemon_chilli", to: charmMenu)
        charmRoot.submenu = charmMenu
        menu.addItem(charmRoot)

        let ropeRoot = NSMenuItem(
            title: "Rope Length",
            action: nil,
            keyEquivalent: ""
        )
        let ropeMenu = NSMenu()
        addRope("Short", 180, to: ropeMenu)
        addRope("Medium", 235, to: ropeMenu)
        addRope("Long", 315, to: ropeMenu)
        ropeRoot.submenu = ropeMenu
        menu.addItem(ropeRoot)

        let sizeRoot = NSMenuItem(
            title: "Charm Size",
            action: nil,
            keyEquivalent: ""
        )
        let sizeMenu = NSMenu()
        addSize("Compact", 120, to: sizeMenu)
        addSize("Standard", 152, to: sizeMenu)
        addSize("Large", 185, to: sizeMenu)
        sizeRoot.submenu = sizeMenu
        menu.addItem(sizeRoot)

        let positionRoot = NSMenuItem(
            title: "Position",
            action: nil,
            keyEquivalent: ""
        )
        let positionMenu = NSMenu()
        addPosition("Left", 0.27, to: positionMenu)
        addPosition("Center", 0.50, to: positionMenu)
        addPosition("Right", 0.73, to: positionMenu)
        positionRoot.submenu = positionMenu
        menu.addItem(positionRoot)

        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: "Show / Hide",
            action: #selector(toggle),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)

        let push = NSMenuItem(
            title: "Give It a Push",
            action: #selector(push),
            keyEquivalent: ""
        )
        push.target = self
        menu.addItem(push)

        let reset = NSMenuItem(
            title: "Reset Physics",
            action: #selector(reset),
            keyEquivalent: ""
        )
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit MyDangle",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    private func addCharm(
        _ title: String,
        _ value: String,
        to menu: NSMenu
    ) {
        let item = NSMenuItem(
            title: title,
            action: #selector(selectCharm(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = value
        menu.addItem(item)
    }

    private func addRope(
        _ title: String,
        _ value: CGFloat,
        to menu: NSMenu
    ) {
        let item = NSMenuItem(
            title: title,
            action: #selector(selectRope(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = Double(value)
        menu.addItem(item)
    }

    private func addSize(
        _ title: String,
        _ value: CGFloat,
        to menu: NSMenu
    ) {
        let item = NSMenuItem(
            title: title,
            action: #selector(selectSize(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = Double(value)
        menu.addItem(item)
    }

    private func addPosition(
        _ title: String,
        _ value: CGFloat,
        to menu: NSMenu
    ) {
        let item = NSMenuItem(
            title: title,
            action: #selector(selectPosition(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = Double(value)
        menu.addItem(item)
    }

    @objc private func selectCharm(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        dangleController.setCharm(value)
    }

    @objc private func selectRope(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        dangleController.setRopeLength(CGFloat(value))
    }

    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        dangleController.setCharmSize(CGFloat(value))
    }

    @objc private func selectPosition(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        dangleController.setPosition(CGFloat(value))
    }

    @objc private func toggle() {
        dangleController.toggle()
    }

    @objc private func push() {
        dangleController.push()
    }

    @objc private func reset() {
        dangleController.reset()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
