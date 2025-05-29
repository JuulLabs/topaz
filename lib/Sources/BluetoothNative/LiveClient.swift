import BluetoothClient
import Dispatch
import EventBus
import Helpers

public func liveBluetoothClient(eventBus: EventBus) -> BluetoothClient {
    let queue = DispatchQueue(label: "bluetooth.live")
    let locker = QueueLockingStrategy(queue: queue)
    let delegate = EventDelegate(locker: locker)
    delegate.handleEvent = eventBus.enqueueEvent
    return Coordinator(queue: queue, locker: locker, delegate: delegate)
}
