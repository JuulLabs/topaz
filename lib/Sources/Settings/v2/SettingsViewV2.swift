import Design
import Permissions
import SwiftUI

public struct SettingsViewV2: View {

    @Bindable var model: SettingsModel

    public init(model: SettingsModel) {
        self.model = model
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .contentShape(Rectangle()) // Ensures the entire area is tappable
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    model.onTapOutside()
                }
            VStack(spacing: 24) {
                settingsButton(systemImageName: "square.on.square", title: "Tabs") {
                    model.tabManagementButtonTapped()
                }
                settingsButton(systemImageName: "square.and.arrow.up", title: "Share") {
                    // TODO: Implement
                }
                settingsButton(systemImageName: "trash", title: "Clear website data") {
                    // TODO: Implement
                }
                settingsButton(image: .bluetooth, title: "Bluetooth® permissions") {
                    model.permissionsButtonTapped()
                }
            }
            .padding(24)
            .frame(maxWidth: 322)
            .background {
                RoundedRectangle(cornerRadius: 48)
                    .fill(Color.cellFillPrimary.opacity(0.97))
                    .blur(radius: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 48)
                    .stroke(.white, lineWidth: 1)
            )
        }
        .padding(.trailing, 16)
        .offset(y: -50)
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
}

#Preview {
    SettingsViewV2(model: SettingsModel())
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
