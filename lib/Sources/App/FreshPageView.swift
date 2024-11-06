import Design
import SwiftUI
import UIHelpers

struct FreshPageView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private let keyboardObserver = KeyboardObserver()

    let model: FreshPageModel

    var body: some View {
        ZStack {
            Color.topaz600
                .ignoresSafeArea(.all)
            topAlignedHeaderView
            centerAlignedSearchView
        }
        .onTapGesture {
            // Tap outside to dismiss the keyboard
            resignFirstResponder()
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
            if !veryLimitedVerticalSpace {
                Text("Topaz")
                    .font(.dogpatch(custom: .launchHeadline, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.top, 30)
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
                SearchBarView(model: model.searchBarModel)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                if !keyboardPresent && !isCompact {
                    Spacer()
                }
            }
        }
        .animation(.spring, value: keyboardPresent)
    }
}

#Preview("New") {
    let model = FreshPageModel(searchBarModel: SearchBarModel())
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loading") {
    let model = FreshPageModel(searchBarModel: SearchBarModel(), isLoading: true)
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
