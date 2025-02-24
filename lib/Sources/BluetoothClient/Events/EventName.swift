
public enum EventName: Sendable {
    case systemState
    case advertisement
    case connect
    case disconnect
    case discoverServices
    case discoverCharacteristics
    case discoverDescriptors
    case characteristicNotify
    case characteristicWrite
    case canSendWriteWithoutResponse
    case characteristicValue
    case descriptorValue
    case descriptorWrite
}
