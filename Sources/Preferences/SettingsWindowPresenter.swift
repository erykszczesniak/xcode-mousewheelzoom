import AppKit
import SwiftUI

/// Owns the Settings window and hosts the SwiftUI hierarchy. Exposed to
/// Objective-C so the menu layer can open Settings without knowing anything
/// about SwiftUI.
@objc(SZSettingsWindowPresenter)
@MainActor
final class SettingsWindowPresenter: NSObject {

    private let preferences: SZPreferences
    private let loginItem: SZLoginItemManaging
    private let trustChecker: SZAccessibilityTrustChecking
    private let openAccessibilitySettings: () -> Void
    private var window: NSWindow?
    private var model: SettingsViewModel?

    @objc init(preferences: SZPreferences,
               loginItem: SZLoginItemManaging,
               trustChecker: SZAccessibilityTrustChecking,
               openAccessibilitySettings: @escaping () -> Void) {
        self.preferences = preferences
        self.loginItem = loginItem
        self.trustChecker = trustChecker
        self.openAccessibilitySettings = openAccessibilitySettings
    }

    @objc func show() {
        if window == nil {
            let model = SettingsViewModel(preferences: preferences,
                                          loginItem: loginItem,
                                          trustChecker: trustChecker,
                                          openAccessibilitySettings: openAccessibilitySettings)
            let hosting = NSHostingController(rootView: SettingsView(model: model))
            let window = NSWindow(contentViewController: hosting)
            window.title = String(localized: "ScrollZoom Settings",
                                  comment: "Settings window title")
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.model = model
            self.window = window

            // Focus doubles as the catch-all refresh: it also picks up
            // external `defaults write` edits and permission changes.
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(windowDidBecomeKey),
                                                   name: NSWindow.didBecomeKeyNotification,
                                                   object: window)
        }

        model?.refresh()
        // An LSUIElement agent is never active on its own; activate so the
        // window can actually become key.
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func windowDidBecomeKey() {
        model?.refresh()
    }
}
