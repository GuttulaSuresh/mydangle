import Cocoa
import ServiceManagement

final class LoginItemManager {
    static let shared = LoginItemManager()

    private init() {}

    private var service: SMAppService {
        SMAppService.mainApp
    }

    var status: SMAppService.Status {
        service.status
    }

    var isOnOrAwaitingApproval: Bool {
        switch service.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    var statusText: String {
        switch service.status {
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Waiting for macOS approval"
        case .notRegistered:
            return "Off"
        case .notFound:
            return "Not available"
        @unknown default:
            return "Unknown"
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if service.status == .notRegistered
                || service.status == .notFound {
                try service.register()
            }
        } else {
            if service.status == .enabled
                || service.status == .requiresApproval {
                try service.unregister()
            }
        }
    }
}


final class ControlWindowController: NSWindowController {
    private let settings: AppSettings
    private let dangleController: DangleController

    private var launchAtLoginButton: NSButton!
    private var launchStatusLabel: NSTextField!
    private var lockVisibilityButton: NSButton!

    init(settings: AppSettings, dangleController: DangleController) {
        self.settings = settings
        self.dangleController = dangleController

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 440),
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
        refreshStartupStatus()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        refreshStartupStatus()
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let title = NSTextField(labelWithString: "🪬 MyDangle")
        title.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        title.frame = NSRect(x: 28, y: 375, width: 370, height: 38)
        content.addSubview(title)

        let subtitle = NSTextField(
            labelWithString:
                "v1.6 — lock/sleep awareness + startup controls"
        )
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 30, y: 347, width: 370, height: 24)
        content.addSubview(subtitle)

        let charmLabel = NSTextField(labelWithString: "Charm")
        charmLabel.frame = NSRect(x: 30, y: 300, width: 80, height: 24)
        content.addSubview(charmLabel)

        let popup = NSPopUpButton(
            frame: NSRect(x: 110, y: 296, width: 250, height: 30),
            pullsDown: false
        )
        popup.addItems(withTitles: ["Bhairava", "Lemon & Chilli"])
        popup.selectItem(
            at: settings.selectedCharm == "lemon_chilli" ? 1 : 0
        )
        popup.target = self
        popup.action = #selector(charmChanged(_:))
        content.addSubview(popup)

        let show = NSButton(
            title: "Show / Hide",
            target: self,
            action: #selector(toggle)
        )
        show.bezelStyle = .rounded
        show.frame = NSRect(x: 30, y: 245, width: 170, height: 34)
        content.addSubview(show)

        let push = NSButton(
            title: "Give It a Push",
            target: self,
            action: #selector(pushCharm)
        )
        push.bezelStyle = .rounded
        push.frame = NSRect(x: 220, y: 245, width: 170, height: 34)
        content.addSubview(push)

        let divider = NSBox(
            frame: NSRect(x: 30, y: 220, width: 360, height: 1)
        )
        divider.boxType = .separator
        content.addSubview(divider)

        let startupTitle = NSTextField(
            labelWithString: "Startup & Lock Behavior"
        )
        startupTitle.font = NSFont.systemFont(
            ofSize: 14,
            weight: .semibold
        )
        startupTitle.frame = NSRect(x: 30, y: 190, width: 300, height: 22)
        content.addSubview(startupTitle)

        launchAtLoginButton = NSButton(
            checkboxWithTitle: "Launch MyDangle at login",
            target: self,
            action: #selector(launchAtLoginChanged(_:))
        )
        launchAtLoginButton.frame =
            NSRect(x: 30, y: 157, width: 300, height: 24)
        content.addSubview(launchAtLoginButton)

        launchStatusLabel = NSTextField(
            labelWithString: ""
        )
        launchStatusLabel.textColor = .secondaryLabelColor
        launchStatusLabel.font = NSFont.systemFont(ofSize: 11)
        launchStatusLabel.frame =
            NSRect(x: 52, y: 137, width: 330, height: 18)
        content.addSubview(launchStatusLabel)

        lockVisibilityButton = NSButton(
            checkboxWithTitle:
                "Experimental lock-screen visibility",
            target: self,
            action: #selector(lockVisibilityChanged(_:))
        )
        lockVisibilityButton.state =
            settings.experimentalLockScreenVisibility ? .on : .off
        lockVisibilityButton.frame =
            NSRect(x: 30, y: 103, width: 330, height: 24)
        content.addSubview(lockVisibilityButton)

        let lockNote = NSTextField(
            wrappingLabelWithString:
                "When enabled, MyDangle asks AppKit to keep the charm eligible for display without login and raises it to screen-saver level while your user session is inactive. The secure macOS password screen may still cover it."
        )
        lockNote.textColor = .secondaryLabelColor
        lockNote.font = NSFont.systemFont(ofSize: 11)
        lockNote.frame = NSRect(x: 52, y: 45, width: 335, height: 54)
        content.addSubview(lockNote)

        let behavior = NSTextField(
            labelWithString:
                "Physics pauses during lock/sleep and resumes smoothly after unlock."
        )
        behavior.textColor = .tertiaryLabelColor
        behavior.font = NSFont.systemFont(ofSize: 10.5)
        behavior.frame = NSRect(x: 30, y: 18, width: 380, height: 18)
        content.addSubview(behavior)
    }

    private func refreshStartupStatus() {
        guard launchAtLoginButton != nil else { return }

        let manager = LoginItemManager.shared
        launchAtLoginButton.state =
            manager.isOnOrAwaitingApproval ? .on : .off
        launchStatusLabel.stringValue =
            "Status: \(manager.statusText)"
    }

    private func showError(_ title: String, _ error: Error) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func charmChanged(_ sender: NSPopUpButton) {
        dangleController.setCharm(
            sender.indexOfSelectedItem == 1
                ? "lemon_chilli"
                : "bhairava"
        )
    }

    @objc private func toggle() {
        dangleController.toggle()
    }

    @objc private func pushCharm() {
        dangleController.push()
    }

    @objc private func launchAtLoginChanged(_ sender: NSButton) {
        do {
            try LoginItemManager.shared.setEnabled(
                sender.state == .on
            )
        } catch {
            showError("Launch at Login", error)
        }

        refreshStartupStatus()
    }

    @objc private func lockVisibilityChanged(_ sender: NSButton) {
        dangleController.setExperimentalLockScreenVisibility(
            sender.state == .on
        )
    }
}
