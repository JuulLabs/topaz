import Design
import SwiftUI

struct FreshPageHeaderView: View {

    var body: some View {
        VStack {
            Image(media: .mainLogo)
            Text("Topaz")
                .font(.dogpatch(custom: .launchHeadline, weight: .bold))
                .foregroundStyle(Color.white)
        }
    }
}
