
public enum EventName: Sendable {
    case systemState
    case advertisement
    case connect
    case disconnect
    case discoverServices
    case discoverCharacteristics
    case discoverDescriptors
    case characteristicNotify
    case characteristicValue
    case descriptorValue
}
