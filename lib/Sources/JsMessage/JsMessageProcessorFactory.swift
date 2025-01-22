
public struct JsMessageProcessorFactory: Sendable {
    public let handlerNames: [String]

    private let builders: [String: @MainActor @Sendable (JsContext) -> JsMessageProcessor]

    public init(builders: [String: @MainActor @Sendable (JsContext) -> JsMessageProcessor] = [:]) {
        self.builders = builders
        self.handlerNames = Array(builders.keys)
    }

    @MainActor
    public func makeProcessor(_ name: String, context: JsContext) -> JsMessageProcessor? {
        builders[name]?(context)
    }
}

/// Convenience instance for previews and testing purposes
public func staticMessageProcessorFactory(
    _ processors: [String: any JsMessageProcessor] = [:]
) -> JsMessageProcessorFactory {
    let builders = processors.reduce(into: [String: @MainActor @Sendable (JsContext) -> JsMessageProcessor]()) { result, element in
        result[element.key] = { @MainActor _ in element.value }
    }
    return JsMessageProcessorFactory(builders: builders)
}
