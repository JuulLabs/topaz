
public actor Debouncer: Sendable {
    private(set) var task: Task<(), Error>?

    public init() {
    }

    public func debounce(
        interval: Duration,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            try await operation()
        }
    }
}
