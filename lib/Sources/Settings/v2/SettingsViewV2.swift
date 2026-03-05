import Design
import SwiftUI

public struct SettingsViewV2: View {

    @Bindable var model: SettingsModel

    public init(model: SettingsModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 24) {
            settingsButton(systemImageName: "square.on.square", title: "Tabs") {
                print("hello")
            }
            settingsButton(systemImageName: "square.and.arrow.up", title: "Share") {

            }
            settingsButton(systemImageName: "trash", title: "Clear website data") {

            }
            settingsButton(image: .bluetooth, title: "Bluetooth® permissions") {

            }
        }
        .padding(24)
//        .cornerRadius(48)
        .background {
            RoundedRectangle(cornerRadius: 48)
                .fill(Color.cellFillPrimary.opacity(0.97))
                .blur(radius: 1)
//            Color.red//.cellFillPrimary.opacity(0.1)
//                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 48))
//                .environment(\.colorScheme, .light)
        }

//        .preferredColorScheme(.light)

//        .background(Color.clear)

//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 48))

//        .background(
////            Color.cellFillPrimary.opacity(0.5)
//            RoundedRectangle(cornerRadius: 48)
//                .stroke(.white, lineWidth: 1)
//                .background(.ultraThinMaterial)
////                .fill(Color.cellFillPrimary)
//
//        )
        .overlay(
            RoundedRectangle(cornerRadius: 48)
                .stroke(.white, lineWidth: 1)
        )
//        .mask(
//            RoundedRectangle(cornerRadius: 48)
//                .stroke(.white, lineWidth: 1)
//        )
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
