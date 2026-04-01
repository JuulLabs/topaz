import Foundation
import JsMessage

struct GeometryChange: Sendable {
    let frame: CGRect?

    init(frame: CGRect? = nil) {
        self.frame = frame
    }

    func toJs(targetId: String) -> JsEvent {
        let rect = frame ?? .zero
        let body: [String: JsConvertable] = [
            "x": Double(rect.origin.x),
            "y": Double(rect.origin.y),
            "width": Double(rect.size.width),
            "height": Double(rect.size.height),
        ]
        return JsEvent(.keyboard, targetId: targetId, eventName: "geometrychange", body: body)
    }
}
