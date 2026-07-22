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
        VStack(spacing: 24) {
            settingsButton(systemImageName: "square.on.square", title: "Tabs") {
                model.tabManagementButtonTapped()
            }
            ShareLink(item: model.shareItem.url, subject: shareSubject) {
                settingsButtonView(title: "Share page", image: Image(systemName: "square.and.arrow.up"))
            }
            .disabled(model.shareItem.isDisabled)
            settingsButton(systemImageName: "trash", title: "Clear website data") {
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
            settingsButton(image: .bluetooth, title: "Bluetooth® permissions") {
                model.permissionsButtonTapped()
            }
            #if DEBUG
            Divider()
            DebugSettings(model: model)
            #endif
        }
        .padding(24)
        .frame(maxWidth: 322)
        .embedInRoundedRectangle(cornerRadius: 48, backgroundColor: Color.cellFillPrimary, opacity: 0.97, borderStroke: 1.0)
        .embedInDismissableModal(trailingPadding: 16, yOffset: -50) {
            model.onTapOutside()
        }
        .sheet(isPresented: $model.permissionsModel.presentPermissionsView, onDismiss: {
            model.permissionsModel.onDismiss()
        }, content: {
            PermissionsView(model: model.permissionsModel)
                .presentationDetents([.fraction(0.98)])
        })
    }
}

#Preview {
    SettingsView(model: SettingsModel())
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
