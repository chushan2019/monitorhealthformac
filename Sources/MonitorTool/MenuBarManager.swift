import AppKit
import Combine

/// Manages the NSStatusItem in the menu bar.
/// Displays formatted metrics text and handles click events for popup/context menu.
@MainActor
final class MenuBarManager: ObservableObject {
    @Published var menuText: String = "Loading..."

    private var statusItem: NSStatusItem?
    let store: MetricsStore
    private var cancellables = Set<AnyCancellable>()
    private var popupWindow: PopupWindow?

    init(store: MetricsStore) {
        self.store = store
    }

    func setup() {
        // variableLength allows the button to resize as text changes
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        button.title = "Loading..."
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        button.bezelStyle = .regularSquare
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
        button.action = #selector(handleClick)

        // Bind store updates to button text
        store.$snapshot
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snap in
                let text = TextFormatter.formatMenuText(snap)
                self?.menuText = text
                self?.statusItem?.button?.title = text
            }
            .store(in: &cancellables)
    }

    func removeStatusBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        popupWindow?.close()
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .leftMouseUp {
            showPopup()
        } else if event.type == .rightMouseUp {
            showContextMenu()
        }
    }

    private func showPopup() {
        if popupWindow == nil {
            popupWindow = PopupWindow(store: self)
        }
        popupWindow?.show()
    }

    @objc private func showPopupFromMenu() {
        showPopup()
    }

    @objc func quitApp() {
        store.stop()
        NSApplication.shared.terminate(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Details", action: #selector(showPopupFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Hide Menu Bar Item", action: #selector(removeStatusBarItem), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MonitorTool", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
    }

    @objc func removeStatusBarItem() {
        // Hide the status bar item (can be reopened by relaunching the app)
        store.stop()
        removeStatusBar()
        // Show a brief alert before fully hiding
        let alert = NSAlert()
        alert.messageText = "Menu Bar Item Hidden"
        alert.informativeText = "The menu bar item has been hidden. To show it again, relaunch MonitorTool.\n\n選單列項目已隱藏。要重新顯示，請重新啟動 MonitorTool。"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Quit")
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSApplication.shared.terminate(nil)
        }
    }
}
