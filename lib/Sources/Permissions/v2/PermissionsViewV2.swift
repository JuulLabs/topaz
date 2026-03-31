import SwiftUI
import UIHelpers

public struct PermissionsViewV2: View {

    @Bindable var model: PermissionsModel

    public init(model: PermissionsModel) {
        self.model = model
    }

    public var body: some View {
        VStack {
            HStack {
                CircleButton(systemImageName: "arrow.left") {
                    model.backButtonTapped()
                }
                Spacer()
                Text("Bluetooth® Permissions")
                    .font(.dogpatch(21))
                    .bold()
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                CircleButton(systemImageName: model.editMode == .active ? "checkmark" : "pencil") {
                    model.editButtonTapped()
                }
            }
            List {
                Section {
                    Text("Allowed Websites").bold()
                    if model.models.isEmpty {
                        Text("Websites that have been granted permission to use Bluetooth will be listed here")
                    } else {
                        ForEach(model.models) { row in
                            Text("\(row.displayString)")
                                .padding(.leading, 20)
                        }
                        .onDelete(perform: model.removeRows)
                        .animation(.interactiveSpring, value: model.models)
                    }
                }
                .listRowBackground(Color.cellFillSecondary)
                .listRowSeparatorTint(Color.clear)
            }
            .environment(\.editMode, $model.editMode)
            .font(.dogpatch(.headline))
            .imageScale(.large)
            .foregroundStyle(Color.textPrimary)
            .scrollContentBackground(.hidden)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
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
        PermissionsViewV2(model: PermissionsModel(origins: origins))
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Empty") {
    NavigationStack {
        PermissionsViewV2(model: PermissionsModel(origins: []))
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
