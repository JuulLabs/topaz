import Design
import Settings
import SwiftUI
import UIHelpers

struct FreshPageView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private let keyboardObserver = KeyboardObserver()

    let model: FreshPageModel

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea(.all)
            topAlignedHeaderView
            searchView
            if model.navBarModel.isSettingsPresented {
                SettingsViewV2(model: model.navBarModel.settingsModel) {
                    model.navBarModel.settingsButtonTapped()
                }
            }
        }
        .onTapGesture {
            // Tap outside to dismiss the keyboard
            resignFirstResponder()
        }
        .onAppear {
            model.onAppear()
        }
    }

    private var isCompact: Bool {
        verticalSizeClass == .compact
    }

    private var keyboardPresent: Bool {
        keyboardObserver.frame != nil
    }

    private var veryLimitedVerticalSpace: Bool {
        keyboardPresent && isCompact
    }

    // Pins to the top, tightens up and drops the text when compact
    @ViewBuilder private var topAlignedHeaderView: some View {
        VStack(spacing: 0) {
            Image(media: .mainLogo)
                .padding(.bottom, -55)
            if !veryLimitedVerticalSpace {
                VStack(spacing: 13) {
                    Text("Topaz")
                        .font(.dogpatch(custom: .launchHeadline, weight: .light))
                        .foregroundStyle(Color.textPrimary)
                    Text("Bluetooth® enabled browser")
                        .font(.dogpatch(.headline))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            Spacer()
        }
        .padding(.top, isCompact ? 6 : 60)
        .animation(.easeIn, value: keyboardPresent)
    }

    @ViewBuilder private var searchView: some View {
        VStack(spacing: 0) {
            Spacer()
            if model.isLoading {
                ProgressView()
                    .controlSize(.extraLarge)
                    .tint(.white)
                    .padding(.bottom, 30)
                Spacer()
            } else {
                NavBarViewV2(model: model.navBarModel)
            }
        }
        .animation(.spring, value: keyboardPresent)
    }
}

#Preview("New") {
    let model = FreshPageModel(navBarModel: NavBarModel(settingsModel: SettingsModel {}) {_ in })
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loading") {
    let model = FreshPageModel(navBarModel: NavBarModel(settingsModel: SettingsModel {}, onFullscreenChanged: {_ in }), isLoading: true)
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
