import Design
import Permissions
import SwiftUI

public struct SettingsView: View {
    @Bindable var model: SettingsModel

    public init(model: SettingsModel) {
        self.model = model
    }

    private var shareSubject: Text? {
        model.shareItem.subject.map(Text.init)
    }

    public var body: some View {
        List {
            Section {
                ShareLink(item: model.shareItem.url, subject: shareSubject) {
                    LabeledContent("Share page") {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .listRowBackground(Color.topaz800)
                .disabled(model.shareItem.isDisabled)

                /* TODO: Implement
                LabeledContent("Set as default homepage") {
                    Image(systemName: "star")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.setDefaultHomeButtonTapped()
                }
                 */

                SearchEngineSelectorView(model: model.searchEngineSelectorModel)

                /* TODO: Implement
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
                 */

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
                .confirmationDialog("Clear website data", isPresented: $model.presentClearCacheDialogue, titleVisibility: .visible, actions: {
                    Button(role: .destructive) {
                        model.removeAllDataButtonTapped()
                    } label: {
                        Text("Remove all data")
                    }
                }, message: {
                    Text("Remove all website data including cache, cookies, etc.")
                })

                LabeledContent("Website Permissions") {
                    Image(systemName: "chevron.right")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.permissionsButtonTapped()
                }

                /*
                LabeledContent("Privacy Policy") {
                    Image(systemName: "chevron.right")
                }
                .listRowTintedButton(color: Color.topaz800) {
                    model.privacyPolicyButtonTapped()
                }
                 */
            }
            .listRowSeparatorTint(Color.borderActive)
        }
        .font(.dogpatch(.headline))
        .imageScale(.large)
        .foregroundStyle(Color.textPrimary)
        .scrollContentBackground(.hidden)
        .background(Color.topaz700)
        .toolbar {
            Button("Done") {
                model.doneButtonTapped()
            }
            .font(.dogpatch(.title2))
            .foregroundStyle(Color.textPrimary)
        }
        .navigationDestination(isPresented: $model.presentPermissionsView) {
            PermissionsView(model: .shared)
                .navigationTitle("Bluetooth Access")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(model: SettingsModel())
            .navigationTitle("Settings")
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
