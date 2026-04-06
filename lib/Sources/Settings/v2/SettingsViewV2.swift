import Design
import Permissions
import SwiftUI

public struct SettingsViewV2: View {

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
            PermissionsViewV2(model: model.permissionsModel)
                .presentationDetents([.fraction(0.98)])
        })
    }

    @ViewBuilder private func settingsButton(systemImageName: String, title: String, action: @escaping () -> Void) -> some View {
        settingsButton(title: title, image: Image(systemName: systemImageName), action: action)
    }

    @ViewBuilder private func settingsButton(image: MediaImage, title: String, action: @escaping () -> Void) -> some View {
        settingsButton(title: title, image: Image(media: image), action: action)
    }

    @ViewBuilder private func settingsButton(title: String, image: Image, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            settingsButtonView(title: title, image: image)
        }
    }

    @ViewBuilder private func settingsButtonView(title: String, image: Image) -> some View {
        HStack(spacing: 8) {
            image
                .foregroundStyle(Color.iconDefault)
                .font(.system(size: 24).weight(.light))
            Text(title)
                .font(.dogpatch(.headline))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    SettingsViewV2(model: SettingsModel())
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
