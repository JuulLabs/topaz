import Semaphore

struct PendingAction {
    private let semaphore = AsyncSemaphore(value: 0)

    let action: Message.Action

    func awaitResolved() async throws {
        try await semaphore.waitUnlessCancelled()
    }

    func resolve() {
        semaphore.signal()
    }
}

extension PendingAction {
    func onResolved<T: JsMessageEncodable>(buildResponse: () -> Result<T, Error>) async -> Result<T, Error> {
        do {
            try await awaitResolved()
        } catch {
            return .failure(error)
        }
        return buildResponse()
    }
}
