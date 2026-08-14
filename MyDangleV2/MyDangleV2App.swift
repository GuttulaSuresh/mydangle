import SwiftUI
import AppKit

@main
struct MyDangleV2App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var dangleController: DangleController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = DangleController()
        dangleController = controller

        statusBarController = StatusBarController(dangleController: controller)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            controller.show()
        }
    }
}
