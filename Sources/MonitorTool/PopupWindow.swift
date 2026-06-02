import AppKit
import SwiftUI

/// Creates an NSPanel with .nonactivatingPanel so it does not steal focus from the frontmost application.
final class PopupWindow {
    private var panel: NSPanel?
    private let store: MetricsStore
    private let menuBarManager: MenuBarManager
    private var hostingView: NSHostingView<PopupView>?

    init(store: MenuBarManager) {
        self.store = store.store
        self.menuBarManager = store
    }

    func show() {
        // Toggle: if already visible, hide it
        if let existing = panel, existing.isVisible {
            existing.orderOut(nil)
            return
        }

        let view = PopupView(store: store, menuBarManager: menuBarManager)
        hostingView = NSHostingView(rootView: view)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered, defer: false
        )

        panel.title = "System Monitor"
        panel.contentView = hostingView
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces]

        // Position below the status item
        if let screenFrame = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(
                x: screenFrame.midX - 190,
                y: screenFrame.maxY - 500
            ))
        }

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}
