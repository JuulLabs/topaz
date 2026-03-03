import Design
import SwiftUI

struct NavIconStripV2: View {

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
                model.navigator.isInSearchMode = true
            } label: {
                systemIcon(imageName: "magnifyingglass", size: 24)
            }
            Spacer()
            Button {
                model.fullscreenButtonTapped()
            } label: {
                customIcon(image: .fullscreenIcon, disabled: model.fullscreenButtonDisabled)
            }
            .disabled(model.fullscreenButtonDisabled)
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
            .foregroundStyle(Color.iconDefault.opacity(disabled ? 0.5 : 1.0))
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

#Preview {
    let model = NavBarModel(tabManagementAction: {}, onFullscreenChanged: { _ in })
    NavIconStripV2(model: model)
}
