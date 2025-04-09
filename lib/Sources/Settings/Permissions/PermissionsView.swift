import Design
import SwiftUI

struct PermissionsView: View {
    @Bindable var model: PermissionsModel

    init(model: PermissionsModel) {
        self.model = model
    }

    var body: some View {
        List {
            Section {
                if model.isLoading {
                    Text("Loading website data...")
                        .listRowBackground(Color.topaz800)
                } else if model.models.isEmpty {
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
        .animation(.spring, value: model.isLoading)
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
