//

import SwiftUI
import Navigation

struct NavBarViewV2: View {

    let model: NavBarModel

    var body: some View {
        HStack(spacing: 20) {
            if model.isInSearchMode {
                SearchBarViewV2(model: model.searchBarModel)
                Button(action: {
                    withAnimation {
                        model.isInSearchMode = false
                    }
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.iconDefault)
                        .font(.system(size: 18).weight(.light))
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.cellFillPrimary) // 2. Add a background color
                        )
                })
            } else {
                Button(action: {
                    withAnimation {
                        model.isInSearchMode = true
                    }
                }, label: {
                    Text("nav mode placeholder")
                })
            }
        }
        .padding([.leading, .trailing], 36)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.8, green: 0.83, blue: 0.93).opacity(0), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.8, green: 0.83, blue: 0.93).opacity(0.95), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
//            .ignoresSafeArea(.all)
//            .blur(radius: 5)
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
//        .blur(radius: 5)
    }
}

#Preview {
    NavBarViewV2(model: NavBarModel(tabManagementAction: {}, onFullscreenChanged: { _ in }))
}
