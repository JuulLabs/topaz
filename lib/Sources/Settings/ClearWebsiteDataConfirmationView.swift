//

import SwiftUI

struct ClearWebsiteDataConfirmationView: View {

    public var body: some View {
        VStack(spacing: 7) {
            VStack {
                Text("Clear website data")
                    .font(
                        .custom("SF Pro", size: 14)
                        .weight(.medium)
                    )
                    .foregroundStyle(Color.darkGrey)
                    .padding(.top, 10)
                Text("Remove all website data including cache, cookies, etc.")
                    .font(.custom("SF Pro", size: 14))
                    .foregroundStyle(Color.darkGrey)
                    .padding(.bottom, 21)
                Rectangle()
                    .foregroundStyle(Color.darkerGrey)
                    .frame(maxWidth: .infinity, maxHeight: 1)

                Button {
                    print("remove data")
                } label: {
                    Text("Remove all data")
                        .font(
                            Font.custom("SF Pro", size: 20)
                            .weight(.medium)
                        )
                        .foregroundStyle(Color.redButton)
                        .frame(maxWidth: .infinity)
                }
                .padding([.top, .bottom], 16)
//                .border(Color.red)
//                .padding(.top, 17)
//                .padding(.bottom, 15)
            }
            .frame(maxWidth: .infinity)
            .background { Color.darkSteel }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
//                    .inset(by: 0.25)
//                    .stroke(Color(red: 0.4, green: 0.4, blue: 0.4), lineWidth: 0.5)
            )

            Button {
                print("cancel")
            } label: {
                Text("Cancel")
                    .font(
                        Font.custom("SF Pro", size: 20)
                        .weight(.medium)
                    )
                    .foregroundStyle(Color.blueButton)
                    .padding([.top, .bottom], 16)
                    .frame(maxWidth: .infinity)
//                    .border(Color.red)
            }
            .frame(maxWidth: .infinity)
            .background { Color.darkSteel }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
        }
//        .frame(idealHeight: 196)
    }
}

#Preview {
    ClearWebsiteDataConfirmationView()
}
