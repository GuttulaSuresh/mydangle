import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusBarController!
    private var dangleController: DangleController!
    private var controlWindowController: ControlWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let settings = AppSettings.shared
        dangleController = DangleController(settings: settings)
        statusController = StatusBarController(
            settings: settings,
            dangleController: dangleController
        )
        controlWindowController = ControlWindowController(
            settings: settings,
            dangleController: dangleController
        )

        // Show immediately. No delayed dispatch during startup.
        dangleController.show()
        controlWindowController.showWindow(nil)
        controlWindowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        dangleController.show()
        controlWindowController.showWindow(nil)
        controlWindowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppSettings.shared.save()
    }
}
