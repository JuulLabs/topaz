import Design
import SwiftUI

public struct PermissionsView: View {
    @Bindable var model: PermissionsModel

    public init(model: PermissionsModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section(header: Text("Allowed Websites")) {
                if model.models.isEmpty {
                    Text("Websites that have been granted permission to use Bluetooth will be listed here")
                } else {
                    ForEach(model.models) { row in
                        Text("\(row.displayString)")
                    }
                    .onDelete(perform: model.removeRows)
                    .animation(.interactiveSpring, value: model.models)
                }
            }
            .listRowBackground(Color.topaz800)
            .listRowSeparatorTint(Color.borderActive)
        }
        .font(.dogpatch(.headline))
        .imageScale(.large)
        .foregroundStyle(Color.textPrimary)
        .scrollContentBackground(.hidden)
        .background(Color.topaz700)
        .toolbar {
            EditButton()
                .font(.dogpatch(.title3))
        }
    }
}

#Preview {
    let origins = [
        WebOrigin(url: URL(string: "https://googlechrome.github.io")!)!,
        WebOrigin(url: URL(string: "https://vueuse.org")!)!,
        WebOrigin(url: URL(string: "https://vueuse.org:8443")!)!,
        WebOrigin(url: URL(string: "https://localhost")!)!,
        WebOrigin(url: URL(string: "http://localhost")!)!,
    ]
    NavigationStack {
        PermissionsView(model: PermissionsModel(origins: origins))
            .navigationTitle("Bluetooth Permissions")
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Empty") {
    NavigationStack {
        PermissionsView(model: PermissionsModel(origins: []))
            .navigationTitle("Bluetooth Permissions")
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
