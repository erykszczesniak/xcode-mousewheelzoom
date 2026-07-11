import SwiftUI

/// The Settings window content. Pure presentation — every change goes
/// through a view-model intent, which writes to the shared preferences
/// store the rest of the app already observes.
struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

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
                            model.removeTarget(target)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help(String(localized: "Remove this app",
                                     comment: "Remove target tooltip"))
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
    }
}
