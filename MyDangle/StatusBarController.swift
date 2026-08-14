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
            button.toolTip = "MyDangle"
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

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

    @objc private func selectCharm(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        dangleController.setCharm(value)
    }

    @objc private func toggle() {
        dangleController.toggle()
    }

    @objc private func push() {
        dangleController.push()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
