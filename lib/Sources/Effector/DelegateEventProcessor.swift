import Bluetooth

public protocol DelegateEventProcessor: Sendable {
    func ingestDelegateEvent(_ event: DelegateEvent) async
    func cancelAllEvents(with error: any Error) async
}
