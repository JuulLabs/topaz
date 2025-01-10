// add start and stop
public enum EventName: Sendable {
    case systemState
    case advertisement
    case connect
    case disconnect
    case discoverServices
    case discoverCharacteristics
    case characteristicNotify
    case characteristicValue
    case startNotifications
    case stopNotifications
}
