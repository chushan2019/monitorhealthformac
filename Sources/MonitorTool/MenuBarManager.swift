import AppKit
import Combine

/// Manages the NSStatusItem in the menu bar.
/// Displays formatted metrics text and handles click events for popup/context menu.
@MainActor
final class MenuBarManager: ObservableObject {
    @Published var menuText: String = "Loading..."

    private var statusItem: NSStatusItem?
    private let store: MetricsStore
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
            popupWindow = PopupWindow(store: store)
        }
        popupWindow?.show()
    }

    @objc private func showPopupFromMenu() {
        showPopup()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Details...", action: #selector(showPopupFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MonitorTool", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
    }
}
