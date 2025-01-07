import SwiftUI

struct WebPagePullDrawer<Drawer: View>: ViewModifier {
    private let model: PullDrawerModel
    @ViewBuilder private let drawer: () -> Drawer

    private let drawerId = "drawerAnimtaionId"
    @Namespace private var animation

    init(model: PullDrawerModel, @ViewBuilder drawer: @escaping () -> Drawer) {
        self.model = model
        self.drawer = drawer
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                if model.status == .open {
                    drawer()
                        .matchedGeometryEffect(id: drawerId, in: animation)
                        .frame(height: model.drawerHeight)
                        .id(drawerId)
                }
                content
            }
            if model.status == .exposed {
                drawer()
                    .matchedGeometryEffect(id: drawerId, in: animation)
                    .frame(height: model.drawerHeight)
                    .id(drawerId)
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(height: model.drawerMaskHeight)
                    }
            }
        }
        .animation(.smooth, value: drawerId)
        .onPreferenceChange(WebPageScrollViewKey.self) { value in
            guard let scrollView = value else { return }
            Task { @MainActor in
                model.observe(scrollView: scrollView)
            }
        }
    }
}

extension View {
    public func webPagePullDrawer<Content: View>(
        _ pullDrawer: PullDrawerModel,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(WebPagePullDrawer(model: pullDrawer, drawer: content))
    }
}
