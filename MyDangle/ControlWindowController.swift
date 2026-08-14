import Cocoa

final class ControlWindowController: NSWindowController {
    private let settings: AppSettings
    private let dangleController: DangleController

    init(settings: AppSettings, dangleController: DangleController) {
        self.settings = settings
        self.dangleController = dangleController

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MyDangle"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.collectionBehavior = [.moveToActiveSpace]
        window.setFrameAutosaveName("MyDangleControlWindow")

        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let title = NSTextField(labelWithString: "🪬 MyDangle")
        title.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        title.frame = NSRect(x: 28, y: 235, width: 330, height: 38)
        content.addSubview(title)

        let subtitle = NSTextField(labelWithString: "Your local hanging charm is running.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 30, y: 207, width: 330, height: 24)
        content.addSubview(subtitle)

        let charmLabel = NSTextField(labelWithString: "Charm")
        charmLabel.frame = NSRect(x: 30, y: 160, width: 80, height: 24)
        content.addSubview(charmLabel)

        let popup = NSPopUpButton(frame: NSRect(x: 110, y: 156, width: 220, height: 30), pullsDown: false)
        popup.addItems(withTitles: ["Bhairava", "Lemon & Chilli"])
        popup.selectItem(at: settings.selectedCharm == "lemon_chilli" ? 1 : 0)
        popup.target = self
        popup.action = #selector(charmChanged(_:))
        content.addSubview(popup)

        let show = NSButton(title: "Show / Hide", target: self, action: #selector(toggle))
        show.bezelStyle = .rounded
        show.frame = NSRect(x: 30, y: 105, width: 150, height: 34)
        content.addSubview(show)

        let push = NSButton(title: "Give It a Push", target: self, action: #selector(pushCharm))
        push.bezelStyle = .rounded
        push.frame = NSRect(x: 195, y: 105, width: 150, height: 34)
        content.addSubview(push)

        let help = NSTextField(wrappingLabelWithString: "Drag the charm on your desktop and flick it. Close this window anytime—the charm keeps running. Double-click MyDangle.app again to reopen these controls.")
        help.textColor = .secondaryLabelColor
        help.frame = NSRect(x: 30, y: 36, width: 330, height: 55)
        content.addSubview(help)
    }

    @objc private func charmChanged(_ sender: NSPopUpButton) {
        dangleController.setCharm(sender.indexOfSelectedItem == 1 ? "lemon_chilli" : "bhairava")
    }
    @objc private func toggle(){dangleController.toggle()}
    @objc private func pushCharm(){dangleController.push()}
}
