import Design
import SwiftUI

struct DownloadRowView: View {
    @Bindable var model: Download

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 6) {
                Text(model.titleText)
                    .foregroundStyle(Color.steel600)
                    .font(.body)
                    .lineLimit(1)
                if let progress = model.progressToShow {
                    ProgressView(value: progress)
                }
                Text(model.subtitleText)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }
            switch model.state {
            case .downloading:
                Spacer()
                Button {
                    model.cancelButtonTapped()
                } label: {
                    Image(systemName: "x.square")
                        .foregroundStyle(Color.topaz300)
                        .imageScale(.large)
                }
            case .finished:
                Spacer()
                Button {
                    model.exportButtonTapped()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.topaz300)
                        .imageScale(.large)
                }
            case .failed:
                Spacer()
            }
        }
        .animation(.snappy, value: model.percentageProgress)
        .animation(.snappy, value: model.bytesProgress)
        .sheet(isPresented: $model.isPresentingShareSheet) {
            ShareSheet(activityItems: [model.destinationURL])
        }
    }

    private var iconName: String {
        switch model.state {
        case .downloading: "arrow.down.circle"
        case .finished: "checkmark.circle"
        case .failed: "exclamationmark.circle"
        }
    }

    private var iconColor: Color {
        switch model.state {
        case .downloading: .topaz300
        case .finished: .green
        case .failed: .redNotification
        }
    }
}

#Preview {
    let url = URL(fileURLWithPath: "/foo/download.bin")
    List {
        DownloadRowView(model: Download(id: 0, destinationURL: url))
        DownloadRowView(model: Download(id: 0, destinationURL: url, percentageProgress: 0.0))
        DownloadRowView(model: Download(id: 0, destinationURL: url, percentageProgress: 0.5))
        DownloadRowView(model: Download(id: 0, destinationURL: url, percentageProgress: 1.0))
        DownloadRowView(model: Download(id: 0, destinationURL: url, bytesProgress: 150_000))
        DownloadRowView(model: Download(id: 0, destinationURL: url, state: .finished))
        DownloadRowView(model: Download(id: 0, destinationURL: url, state: .finished, bytesProgress: 1024))
        DownloadRowView(model: Download(id: 0, destinationURL: url, state: .failed))
        DownloadRowView(model: Download(id: 0, destinationURL: url, state: .failed, errorDescription: "Custom error"))
    }
}
