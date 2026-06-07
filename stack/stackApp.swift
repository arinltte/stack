//
//  stackApp.swift
//  stack
//

import SwiftUI

@main
struct stack: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

extension Notification.Name {
    static let windowMovableChanged = Notification.Name("windowMovableChanged")
    static let menuBarIconChanged = Notification.Name("menuBarIconChanged")
}

// MARK: - Custom Hover View for Menu Bar
class MenuBarDragView: NSView {
    var onDragEntered: (() -> Void)?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        // Registering enables this view to receive hover drag events natively
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onDragEntered?()
        return [] // Fixed unavailable error: natively accepts hover effect side-action
    }
    
    // Explicitly pass clicks to the underlying NSStatusBarButton so it acts natively
    override func mouseDown(with event: NSEvent) {
        if let btn = superview as? NSButton {
            btn.mouseDown(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if let btn = superview as? NSButton {
            btn.mouseUp(with: event)
        } else {
            super.mouseUp(with: event)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var floatingPanel: FloatingPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupFloatingPanel()
        setupNotifications()
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            let iconName = UserDefaults.standard.string(forKey: "menuBarIcon") ?? "doc.on.doc.fill"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Stack")
            button.action = #selector(statusBarClicked)
            
            // Add custom transparent view to intercept drag-hovers smoothly
            let dragView = MenuBarDragView(frame: button.bounds)
            dragView.autoresizingMask = [.width, .height]
            dragView.onDragEntered = { [weak self] in
                if self?.floatingPanel.isVisible == false {
                    self?.showPanel()
                }
            }
            button.addSubview(dragView)
        }
    }

    func setupFloatingPanel() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let panelWidth: CGFloat = 380
        let initialHeight: CGFloat = 260 // Aligned perfectly to the new compact baseline UI

        let panelX = screenRect.maxX - panelWidth - 10
        let panelY = screenRect.maxY - initialHeight

        let panelRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: initialHeight)

        floatingPanel = FloatingPanel(
            contentRect: panelRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let contentView = StackView(onClose: { [weak self] in
            self?.hidePanel()
        })

        floatingPanel.contentView = NSHostingView(rootView: contentView)
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .windowMovableChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let isMovable = notification.userInfo?["value"] as? Bool ?? false
            self?.floatingPanel.isMovableByWindowBackground = isMovable
        }
        
        NotificationCenter.default.addObserver(
            forName: .menuBarIconChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let icon = notification.userInfo?["icon"] as? String {
                self?.statusItem?.button?.image = NSImage(systemSymbolName: icon, accessibilityDescription: "Stack")
            }
        }
    }

    @objc func statusBarClicked() {
        togglePanel()
    }

    func togglePanel() {
        if floatingPanel.isVisible { hidePanel() } else { showPanel() }
    }

    func showPanel() {
        if !floatingPanel.isMovableByWindowBackground {
            let screenRect = NSScreen.main?.visibleFrame ?? .zero
            var frame = floatingPanel.frame

            if let button = statusItem?.button, let buttonWindow = button.window {
                let buttonFrame = buttonWindow.convertToScreen(button.bounds)
                frame.origin.x = buttonFrame.midX - frame.width / 2
            } else {
                frame.origin.x = screenRect.maxX - frame.width - 10
            }

            frame.origin.x = max(10, frame.origin.x)
            frame.origin.y = screenRect.maxY - frame.height

            floatingPanel.setFrame(frame, display: true)
        }

        floatingPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        floatingPanel.orderOut(nil)
    }
}
