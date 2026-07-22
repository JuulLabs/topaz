import SwiftUI

struct DebugSettings: View {
    @Bindable var model: SettingsModel

    var body: some View {
        VStack(spacing: 24) {
            if !model.isDownloadsDisabled {
                settingsButton(systemImageName: "chevron.right", title: "Recent Downloads") {
                    model.downloadsButtonTapped()
                }
            }

            settingsButton(systemImageName: "xmark.octagon", title: "Clear browsing history") {
                model.clearHistoryButtonTapped()
            }

            SearchEngineSelectorView(model: model.searchEngineSelectorModel)
        }
    }
}

#Preview {
    DebugSettings(model: SettingsModel())
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
