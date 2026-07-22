import Design
import SwiftUI

@ViewBuilder
func settingsButton(
    systemImageName: String,
    title: String,
    action: @MainActor @escaping () -> Void
) -> some View {
    settingsButton(title: title, image: Image(systemName: systemImageName), action: action)
}

@ViewBuilder
func settingsButton(
    image: MediaImage,
    title: String,
    action: @MainActor @escaping () -> Void
) -> some View {
    settingsButton(title: title, image: Image(media: image), action: action)
}

@ViewBuilder
func settingsButton(
    title: String,
    image: Image,
    action: @MainActor @escaping () -> Void
) -> some View {
    Button {
        action()
    } label: {
        settingsButtonView(title: title, image: image)
    }
}

@ViewBuilder
func settingsButtonView(
    title: String,
    image: Image
) -> some View {
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
