
/// Maps a handler name to a builder that constructs its processor for a given JS context.
/// Builders close over whatever scope they're created in: app-level builders capture
/// app-wide singletons, while page-level builders capture per-page collaborators.
public typealias JsMessageProcessorBuilders = [String: @MainActor @Sendable (JsContext) -> JsMessageProcessor]

public struct JsMessageProcessorFactory: Sendable {
    public let handlerNames: [String]

    private let builders: JsMessageProcessorBuilders

    public init(builders: JsMessageProcessorBuilders = [:]) {
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
    let builders = processors.reduce(into: JsMessageProcessorBuilders()) { result, element in
        result[element.key] = { @MainActor _ in element.value }
    }
    return JsMessageProcessorFactory(builders: builders)
}
