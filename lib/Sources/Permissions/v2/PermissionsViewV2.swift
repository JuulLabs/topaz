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
//                Section(header: Text("Allowed Websites")) {
                Section {
                    Text("Allowed Websites").bold()
                    if model.models.isEmpty {
                        Text("Websites that have been granted permission to use Bluetooth will be listed here")
                    } else {
                        ForEach(model.models) { row in
                            Text("\(row.displayString)")
                                .padding(.leading, 20)
//                                .listRowBackground(Color.cellFillSecondary)
                        }
                        .onDelete(perform: model.removeRows)
                        .animation(.interactiveSpring, value: model.models)
//                        .listRowInsets(EdgeInsets())
                    }
                }
//                .padding(0)
//                .border(Color.green)
//                .background(Color.red)
                .listRowBackground(Color.cellFillSecondary)
                .listRowSeparatorTint(Color.clear)
            }
            .environment(\.editMode, $model.editMode)
//            .background(Color.cellFillSecondary)
            .font(.dogpatch(.headline))
            .imageScale(.large)
            .foregroundStyle(Color.textPrimary)
            .scrollContentBackground(.hidden)
//            .border(Color.green)
//            .listStyle(.plain)
//            .cornerRadius(15)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
//        .background(.ultraThinMaterial)
//        .background(Color.clear)
//        .border(Color.red)
//        .background(Color.cellFillPrimary.opacity(0.75))
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
//            .navigationTitle("Bluetooth Permissions")
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Empty") {
    NavigationStack {
        PermissionsViewV2(model: PermissionsModel(origins: []))
//            .navigationTitle("Bluetooth Permissions")
    }
    .accentColor(.white)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
