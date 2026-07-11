import SwiftUI

/// The Settings window content. Pure presentation — every change goes
/// through a view-model intent, which writes to the shared preferences
/// store the rest of the app already observes.
struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel
    @State private var targetPendingRemoval: SettingsViewModel.Target?

    var body: some View {
        Form {
            if !model.isPermissionGranted {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(String(localized: "Accessibility permission needed",
                                    comment: "Settings permission banner"))
                        Spacer()
                        Button(String(localized: "Open Accessibility Settings…",
                                      comment: "Deep link to the Accessibility privacy pane")) {
                            model.openAccessibilitySettings()
                        }
                    }
                }
            }

            Section {
                Toggle(String(localized: "Enabled", comment: "Master switch"),
                       isOn: Binding(get: { model.isAgentEnabled },
                                     set: { model.setAgentEnabled($0) }))
                Toggle(String(localized: "Start at Login", comment: "Login item toggle"),
                       isOn: Binding(get: { model.isLoginItemEnabled },
                                     set: { model.setLoginItemEnabled($0) }))
            }

            Section {
                Slider(value: Binding(get: { model.sensitivity },
                                      set: { model.setSensitivity($0) }),
                       in: 0...1) {
                    Text(String(localized: "Sensitivity", comment: "Slider label"))
                } minimumValueLabel: {
                    Text(String(localized: "Low", comment: "Least sensitive"))
                } maximumValueLabel: {
                    Text(String(localized: "High", comment: "Most sensitive"))
                }
            } footer: {
                Text(String(localized: "How far a trackpad swipe travels per zoom step.",
                            comment: "Sensitivity explanation"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Targets", comment: "Target apps section")) {
                ForEach(model.targets) { target in
                    HStack {
                        Toggle(isOn: Binding(get: { target.isEnabled },
                                             set: { model.setTarget(target, enabled: $0) })) {
                            VStack(alignment: .leading) {
                                Text(target.displayName)
                                Text(target.id)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button(role: .destructive) {
                            targetPendingRemoval = target
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help(String(localized: "Remove this app",
                                     comment: "Remove target tooltip"))
                    }
                }

                if model.targets.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "No target apps",
                                    comment: "Empty state title in the targets list"))
                        Text(String(localized: "ScrollZoom stays idle until you add one.",
                                    comment: "Empty state body in the targets list"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(String(localized: "Add Application…", comment: "Add target button")) {
                    model.presentAddTargetPanel()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 420)
        .alert(String(localized: "Something went wrong", comment: "Settings error title"),
               isPresented: Binding(get: { model.lastErrorMessage != nil },
                                    set: { if !$0 { model.lastErrorMessage = nil } })) {
            Button(String(localized: "OK", comment: "Dismiss error")) {
                model.lastErrorMessage = nil
            }
        } message: {
            Text(model.lastErrorMessage ?? "")
        }
        .confirmationDialog(
            targetPendingRemoval.map {
                String(format: String(localized: "Remove %@ from the target list?",
                                      comment: "Confirmation title when removing a target"),
                       $0.displayName)
            } ?? "",
            isPresented: Binding(get: { targetPendingRemoval != nil },
                                 set: { if !$0 { targetPendingRemoval = nil } }),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Remove", comment: "Destructive confirm button"),
                   role: .destructive) {
                if let target = targetPendingRemoval {
                    model.removeTarget(target)
                }
                targetPendingRemoval = nil
            }
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                targetPendingRemoval = nil
            }
        } message: {
            Text(String(localized: "⌘ + scroll will stop zooming in that app. You can add it back at any time.",
                        comment: "Confirmation body when removing a target"))
        }
    }
}
