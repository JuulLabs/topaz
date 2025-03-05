//

import SwiftUI
import WebKit

struct ClearWebsiteDataConfirmationView: View {

    let model: SettingsModel

    public var body: some View {
        VStack(spacing: 7) {
            VStack {
                Text("Clear website data")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.darkGrey)
                    .padding(.top, 10)
                Text("Remove all website data including cache, cookies, etc.")
                    .font(.subheadline)
                    .foregroundStyle(Color.darkGrey)
                    .padding(.bottom, 21)

                Rectangle()
                    .foregroundStyle(Color.darkerGrey)
                    .frame(maxWidth: .infinity, maxHeight: 1)

                Button {
                    model.removeAllDataButtonTapped()
                } label: {
                    Text("Remove all data")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.redButton)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 7)
                .padding(.bottom, 17)
            }
            .frame(maxWidth: .infinity)
            .background { Color.darkSteel }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )

            Button {
                model.cancelClearCacheButtonTapped()
            } label: {
                Text("Cancel")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.blueButton)
                    .padding([.top, .bottom], 16)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .background { Color.darkSteel }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
        }
    }
}

#Preview {
    ClearWebsiteDataConfirmationView(model: SettingsModel())
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
