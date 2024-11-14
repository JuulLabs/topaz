import Bluetooth

extension DelegateEvent {
    func toJsEvent() -> JsEventEncodable? {
        switch self {
        case let .systemState(state):
            AvailabilityEvent(state: state)
        case let .disconnected(peripheral, _):
            // TODO: can we forward the error here somehow?
            DisconnectEvent(peripheralId: peripheral.identifier)
        default:
            nil
        }
    }
}
