import Design
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
            centerAlignedSearchView
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
        VStack(spacing: -55) {
            Image(media: .mainLogo)
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

    // Pins to the center normally and to the bottom when compact or keyboard is up
    @ViewBuilder private var centerAlignedSearchView: some View {
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
    let model = FreshPageModel(navBarModel: NavBarModel(tabManagementAction: {}, onFullscreenChanged: {_ in }))
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loading") {
    let model = FreshPageModel(navBarModel: NavBarModel(tabManagementAction: {}, onFullscreenChanged: {_ in }), isLoading: true)
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
