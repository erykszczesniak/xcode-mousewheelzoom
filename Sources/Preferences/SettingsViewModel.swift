import AppKit
import Combine
import UniformTypeIdentifiers

/// Bridges the Objective-C `SZPreferences` store into SwiftUI. Writes go
/// straight through the store. Re-publishing happens on
/// `SZPreferencesDidChangeNotification` (any in-app mutation: window, menu,
/// hotkey), on `SZLoginItemDidChangeNotification`, and on every window
/// focus via `refresh()` — which also picks up external `defaults write`
/// edits the next time the user returns to the window.
@MainActor
final class SettingsViewModel: ObservableObject {

    struct Target: Identifiable, Equatable {
        let id: String // bundle identifier
        let displayName: String
        var isEnabled: Bool
    }

    @Published private(set) var isPermissionGranted = true
    @Published private(set) var isAgentEnabled = true
    @Published private(set) var isLoginItemEnabled = false
    /// 0 (least sensitive) … 1 (most sensitive), mapped onto the trackpad
    /// px-per-step threshold.
    @Published private(set) var sensitivity = 0.5
    @Published private(set) var targets: [Target] = []
    @Published var lastErrorMessage: String?

    private let preferences: SZPreferences
    private let loginItem: SZLoginItemManaging
    private let trustChecker: SZAccessibilityTrustChecking
    private let openAccessibilitySettingsAction: () -> Void

    private static let leastSensitiveThreshold = 25.0
    private static let mostSensitiveThreshold = 8.0

    init(preferences: SZPreferences,
         loginItem: SZLoginItemManaging,
         trustChecker: SZAccessibilityTrustChecking,
         openAccessibilitySettings: @escaping () -> Void) {
        self.preferences = preferences
        self.loginItem = loginItem
        self.trustChecker = trustChecker
        self.openAccessibilitySettingsAction = openAccessibilitySettings
        refresh()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(externalStateDidChange),
                                               name: .SZPreferencesDidChange,
                                               object: preferences)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(externalStateDidChange),
                                               name: .SZLoginItemDidChange,
                                               object: nil)
    }

    @objc private func externalStateDidChange() {
        refresh()
    }

    /// Re-reads everything from the underlying stores. Called by the window
    /// presenter whenever the window becomes key.
    func refresh() {
        isPermissionGranted = trustChecker.isProcessTrusted
        isAgentEnabled = preferences.isEnabled
        isLoginItemEnabled = loginItem.isEnabled
        sensitivity = Self.sensitivity(fromThreshold: preferences.preciseDeltaThreshold)
        targets = preferences.configuredTargetRules.map { rule in
            Target(id: rule.bundleIdentifier,
                   displayName: Self.displayName(forBundleIdentifier: rule.bundleIdentifier),
                   isEnabled: preferences.isTargetEnabled(rule.bundleIdentifier))
        }
    }

    // MARK: - Intents

    func setAgentEnabled(_ enabled: Bool) {
        preferences.isEnabled = enabled
    }

    func setLoginItemEnabled(_ enabled: Bool) {
        do {
            try loginItem.setEnabled(enabled)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        refresh()
    }

    func setSensitivity(_ value: Double) {
        preferences.preciseDeltaThreshold = Self.threshold(fromSensitivity: value)
    }

    func setTarget(_ target: Target, enabled: Bool) {
        preferences.setTarget(target.id, enabled: enabled)
    }

    func removeTarget(_ target: Target) {
        preferences.removeTarget(withBundleIdentifier: target.id)
    }

    func openAccessibilitySettings() {
        openAccessibilitySettingsAction()
    }

    /// Lets the user pick an .app bundle; its bundle identifier becomes a
    /// new role-agnostic target rule.
    func presentAddTargetPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let bundleIdentifier = Bundle(url: url)?.bundleIdentifier else {
            lastErrorMessage = String(
                format: SZLocalizedSettingsNoBundleIdentifierFormat(), url.lastPathComponent)
            return
        }
        if !preferences.addTarget(withBundleIdentifier: bundleIdentifier) {
            lastErrorMessage = String(
                format: SZLocalizedSettingsDuplicateTargetFormat(), bundleIdentifier)
        }
    }

    // MARK: - Mapping helpers

    private static func sensitivity(fromThreshold threshold: Double) -> Double {
        let span = leastSensitiveThreshold - mostSensitiveThreshold
        let clamped = min(max(threshold, mostSensitiveThreshold), leastSensitiveThreshold)
        return (leastSensitiveThreshold - clamped) / span
    }

    private static func threshold(fromSensitivity sensitivity: Double) -> Double {
        let span = leastSensitiveThreshold - mostSensitiveThreshold
        let clamped = min(max(sensitivity, 0), 1)
        return leastSensitiveThreshold - clamped * span
    }

    private static func displayName(forBundleIdentifier bundleIdentifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier) else {
            return bundleIdentifier
        }
        let name = FileManager.default.displayName(atPath: url.path)
        return name.isEmpty ? bundleIdentifier : name
    }
}
