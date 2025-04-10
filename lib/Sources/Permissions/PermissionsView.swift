import Design
import SwiftUI

public struct PermissionsView: View {
    @Bindable var model: PermissionsModel

    public init(model: PermissionsModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                if model.models.isEmpty {
                    Text("Websites that are granted permission to use Bluetooth will be listed here")
                        .listRowBackground(Color.topaz800)
                } else {
                    ForEach(model.models) { row in
                        Text("\(row.displayString)")
                            .listRowBackground(Color.topaz800)
                    }
                    .onDelete(perform: model.removeRows)
                    .animation(.interactiveSpring, value: model.models)
                }
            }
            .listRowSeparatorTint(Color.borderActive)
        }
        .font(.dogpatch(.headline))
        .imageScale(.large)
        .foregroundStyle(Color.textPrimary)
        .scrollContentBackground(.hidden)
        .background(Color.topaz700)
    }
}

#Preview {
    let origins = [
        WebOrigin(domain: "googlechrome.github.io", scheme: "https", port: 443),
        WebOrigin(domain: "vueuse.org", scheme: "https", port: 443),
    ]
    NavigationStack {
        PermissionsView(model: PermissionsModel(origins: origins))
            .navigationTitle("Bluetooth Access")
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
