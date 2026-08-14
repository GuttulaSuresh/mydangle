import Cocoa

final class StatusBarController: NSObject, NSMenuDelegate {
    private let settings: AppSettings
    private let dangleController: DangleWindowController

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    init(settings: AppSettings, dangleController: DangleWindowController) {
        self.settings = settings
        self.dangleController = dangleController
        super.init()

        if let button = statusItem.button {
            button.image = nil
            button.title = "🧿 MyDangle"
            button.toolTip = "MyDangle"
        }

        statusItem.isVisible = true

        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
        installGlobalShortcut()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let toggleTitle = settings.isVisible ? "Hide Dangle" : "Show Dangle"
        let toggle = NSMenuItem(title: toggleTitle, action: #selector(toggleDangle), keyEquivalent: "d")
        toggle.keyEquivalentModifierMask = [.control, .option]
        toggle.target = self
        menu.addItem(toggle)

        let kick = NSMenuItem(title: "Give It a Push", action: #selector(kickDangle), keyEquivalent: "k")
        kick.keyEquivalentModifierMask = [.control, .option]
        kick.target = self
        menu.addItem(kick)

        menu.addItem(.separator())

        let charmMenu = NSMenu()
        let charmItem = NSMenuItem(title: "Charm", action: nil, keyEquivalent: "")
        charmItem.submenu = charmMenu

        for charm in ["🧿", "🍋", "🌶️", "⭐️", "🪬", "❤️", "☕️", "🦈", "🌙", "🍀"] {
            let item = NSMenuItem(title: "\(charm)  \(name(for: charm))", action: #selector(selectCharm(_:)), keyEquivalent: "")
            item.representedObject = charm
            item.state = settings.charm == charm ? .on : .off
            item.target = self
            charmMenu.addItem(item)
        }
        menu.addItem(charmItem)

        let lengthMenu = NSMenu()
        let lengthItem = NSMenuItem(title: "Rope Length", action: nil, keyEquivalent: "")
        lengthItem.submenu = lengthMenu

        for value in [160, 220, 280, 360, 440] {
            let item = NSMenuItem(title: "\(value) pt", action: #selector(selectLength(_:)), keyEquivalent: "")
            item.representedObject = value
            item.state = abs(settings.ropeLength - CGFloat(value)) < 1 ? .on : .off
            item.target = self
            lengthMenu.addItem(item)
        }
        menu.addItem(lengthItem)

        let sizeMenu = NSMenu()
        let sizeItem = NSMenuItem(title: "Charm Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu

        for value in [36, 48, 60, 72, 88] {
            let item = NSMenuItem(title: "\(value) pt", action: #selector(selectSize(_:)), keyEquivalent: "")
            item.representedObject = value
            item.state = abs(settings.charmSize - CGFloat(value)) < 1 ? .on : .off
            item.target = self
            sizeMenu.addItem(item)
        }
        menu.addItem(sizeItem)

        let positionMenu = NSMenu()
        let positionItem = NSMenuItem(title: "Horizontal Position", action: nil, keyEquivalent: "")
        positionItem.submenu = positionMenu

        let positions: [(String, CGFloat)] = [
            ("Far Left", 0.12),
            ("Left", 0.30),
            ("Center", 0.50),
            ("Right", 0.70),
            ("Far Right", 0.88)
        ]

        for (title, fraction) in positions {
            let item = NSMenuItem(title: title, action: #selector(selectPosition(_:)), keyEquivalent: "")
            item.representedObject = Double(fraction)
            item.state = abs(settings.anchorFraction - fraction) < 0.06 ? .on : .off
            item.target = self
            positionMenu.addItem(item)
        }
        menu.addItem(positionItem)

        menu.addItem(.separator())

        let reset = NSMenuItem(title: "Reset Dangle", action: #selector(resetDangle), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        let quit = NSMenuItem(title: "Quit MyDangle", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func installGlobalShortcut() {
        // A lightweight global shortcut that does not require Accessibility permission.
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.control, .option]) else { return }
            if event.charactersIgnoringModifiers?.lowercased() == "d" {
                DispatchQueue.main.async {
                    self?.dangleController.toggle()
                }
            } else if event.charactersIgnoringModifiers?.lowercased() == "k" {
                DispatchQueue.main.async {
                    self?.dangleController.kick()
                }
            }
        }
    }

    @objc private func toggleDangle() {
        dangleController.toggle()
    }

    @objc private func kickDangle() {
        dangleController.kick()
    }

    @objc private func selectCharm(_ sender: NSMenuItem) {
        guard let charm = sender.representedObject as? String else { return }
        settings.charm = charm
        settings.save()
        dangleController.refreshLayout()
    }

    @objc private func selectLength(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Int else { return }
        settings.ropeLength = CGFloat(value)
        dangleController.refreshLayout()
    }

    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Int else { return }
        settings.charmSize = CGFloat(value)
        dangleController.refreshLayout()
    }

    @objc private func selectPosition(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        dangleController.setHorizontalPosition(CGFloat(value))
    }

    @objc private func resetDangle() {
        settings.reset()
        dangleController.rebuild()
        dangleController.resetPhysics()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func name(for charm: String) -> String {
        switch charm {
        case "🧿": return "Nazar"
        case "🍋": return "Lemon"
        case "🌶️": return "Chilli"
        case "⭐️": return "Star"
        case "🪬": return "Hamsa"
        case "❤️": return "Heart"
        case "☕️": return "Coffee"
        case "🦈": return "Shark"
        case "🌙": return "Moon"
        case "🍀": return "Clover"
        default: return "Charm"
        }
    }
}
