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
