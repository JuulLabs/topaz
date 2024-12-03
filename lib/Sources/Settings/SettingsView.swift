import Design
import SwiftUI

public struct SettingsView: View {
    @Bindable var model: SettingsModel

    public init(model: SettingsModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                LabeledContent("Share page") {
                    Image(systemName: "square.and.arrow.up")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.shareButtonTapped()
                }

                LabeledContent("New tab") {
                    Image(systemName: "plus")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.newTabButtonTapped()
                }

                LabeledContent("Set as default homepage") {
                    Image(systemName: "star")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.setDefaultHomeButtonTapped()
                }

                Toggle(isOn: $model.bluetoothEnabled) {
                    Text("Bluetooth® permissions")
                }
                .listRowBackground(Color.topaz800)

                LabeledContent("Logs") {
                    Image(systemName: "chevron.right")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.logsButtonTapped()
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Use HStack with a spacer to force a full-width hitbox
                    HStack {
                        Text("Clear browsing history")
                        Spacer()
                    }
                    Text("Clear all browsing history and data")
                        .font(.dogpatch(.footnote))
                        .foregroundStyle(.secondary)
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.clearHistoryButtonTapped()
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Use HStack with a spacer to force a full-width hitbox
                    HStack {
                        Text("Clear website data")
                        Spacer()
                    }
                    Text("Remove all data including caches and cookies")
                        .font(.dogpatch(.footnote))
                        .foregroundStyle(.secondary)
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.clearCacheButtonTapped()
                }

                LabeledContent("Privacy Policy") {
                    Image(systemName: "chevron.right")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.privacyPolicyButtonTapped()
                }
            }
            .listRowSeparatorTint(Color.borderActive)
        }
        .font(.dogpatch(.headline))
        .imageScale(.large)
        .foregroundStyle(Color.textPrimary)
        .scrollContentBackground(.hidden)
        .background(Color.topaz700)
    }
}

#Preview {
    NavigationStack {
        SettingsView(model: SettingsModel())
            .navigationTitle("Settings")
    }
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
