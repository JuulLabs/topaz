import Settings
import SwiftUI
import UIHelpers
import Navigation

struct NavBarViewV2: View {

    let model: NavBarModel

    var body: some View {
        HStack(spacing: 20) {
            if model.navigator.isInSearchMode {
                SearchBarViewV2(model: model.searchBarModel)
                Button(action: {
                    model.navigator.isInSearchMode = false
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.iconDefault)
                        .font(.system(size: 18).weight(.light))
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.cellFillPrimary)
                        )
                })
            } else {
                NavIconStripV2(model: model)
            }
        }
        .animation(.spring, value: model.navigator.isInSearchMode)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .embedInNavigationBackground(keyboardPresent: model.keyboardPresent)
    }
}

#Preview {
    NavBarViewV2(model: NavBarModel(settingsModel: SettingsModel(), onFullscreenChanged: { _ in }))
}
