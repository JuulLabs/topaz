import Design
import SwiftUI

struct NavIconStrip: View {
    let model: NavBarModel

    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.backButtonTapped()
            } label: {
                systemIcon(imageName: "chevron.left", disabled: model.backButtonDisabled)
            }
            .disabled(model.backButtonDisabled)
            Spacer()
            Button {
                model.forwardButtonTapped()
            } label: {
                systemIcon(imageName: "chevron.right", disabled: model.forwardButtonDisabled)
            }
            .disabled(model.forwardButtonDisabled)
            Spacer()
            Button {
                model.fullscreenButtonTapped()
            } label: {
                customIcon(image: .fullscreenIcon, disabled: model.fullscreenButtonDisabled)
            }
            .disabled(model.fullscreenButtonDisabled)
            Spacer()
            Button {
                model.tabManagementButtonTapped()
            } label: {
                systemIcon(imageName: "square.on.square", size: 28)
            }
            Spacer()
            Button {
                model.settingsButtonTapped()
            } label: {
                customIcon(image: .settingsIcon)
            }
        }
    }

    @ViewBuilder private func systemIcon(
        imageName: String,
        disabled: Bool = false,
        size: CGFloat = 32
    ) -> some View {
        Image(systemName: imageName)
            .font(.system(size: size).weight(.light))
            .foregroundStyle(Color(white: 1.0, opacity: disabled ? 0.5 : 1.0))
            .padding(8) // For a larger hit box
    }

    @ViewBuilder private func customIcon(
        image: MediaImage,
        disabled: Bool = false
    ) -> some View {
        Image(media: image)
            .opacity(disabled ? 0.5 : 1.0)
            .padding(8) // For a larger hit box
    }
}

#Preview("Enabled") {
    NavIconStrip(
        model: previewModel(disabled: false)
    )
    .background(Color.topaz600)
}

#Preview("Disabled") {
    NavIconStrip(
        model: previewModel(disabled: true)
    )
    .background(Color.topaz600)
}

@MainActor
private func previewModel(disabled: Bool) -> NavBarModel {
    let model = NavBarModel(tabManagementAction: {}, onFullscreenChanged: { _ in })
    model.fullscreenButtonDisabled = disabled
    return model
}
