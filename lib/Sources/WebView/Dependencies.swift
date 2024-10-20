import JsMessage
import SwiftUI

public struct JsMessageProcessorsKey: EnvironmentKey {
    public static let defaultValue: [JsMessageProcessor] = []
}

extension EnvironmentValues {
  public var jsMessageProcessors: [JsMessageProcessor] {
    get { self[JsMessageProcessorsKey.self] }
    set { self[JsMessageProcessorsKey.self] = newValue }
  }
}
