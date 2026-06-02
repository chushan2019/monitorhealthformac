import SwiftUI
import AppKit

@main
struct MonitorToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Minimal Settings window (can be expanded later)
        Settings {
            Text("MonitorTool Settings")
                .frame(width: 300, height: 200)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var store: MetricsStore!
    var menuBarManager: MenuBarManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = MetricsStore()
        menuBarManager = MenuBarManager(store: store)
        menuBarManager.setup()
        store.start(interval: 1.0)
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
    }
}
