import Bluetooth
import Foundation

public struct RequestClient: Sendable {
    public var enable: @Sendable () -> Void
    public var disable: @Sendable () -> Void
    public var startScanning: @Sendable (Filter) -> Void
    public var stopScanning: @Sendable () -> Void
    public var connect: @Sendable (AnyPeripheral) -> Void
    public var disconnect: @Sendable (AnyPeripheral) -> Void
    public var discoverServices: @Sendable (AnyPeripheral, ServiceDiscoveryFilter) -> Void
    public var discoverCharacteristics: @Sendable (AnyPeripheral, CharacteristicDiscoveryFilter) -> Void
    public var readCharacteristic: @Sendable (AnyPeripheral, _ service: UUID, _ characteristic: UUID, _ instance: UInt32) throws -> Void

    public init(
        enable: @Sendable @escaping () -> Void,
        disable: @Sendable @escaping () -> Void,
        startScanning: @Sendable @escaping (Filter) -> Void,
        stopScanning: @Sendable @escaping () -> Void,
        connect: @Sendable @escaping (AnyPeripheral) -> Void,
        disconnect: @Sendable @escaping (AnyPeripheral) -> Void,
        discoverServices: @Sendable @escaping (AnyPeripheral, ServiceDiscoveryFilter) -> Void,
        discoverCharacteristics: @Sendable @escaping (AnyPeripheral, CharacteristicDiscoveryFilter) -> Void,
        readCharacteristic: @Sendable @escaping (AnyPeripheral, _ service: UUID, _ characteristic: UUID, _ instance: UInt32) throws -> Void
    ) {
        self.enable = enable
        self.disable = disable
        self.startScanning = startScanning
        self.stopScanning = stopScanning
        self.connect = connect
        self.disconnect = disconnect
        self.discoverServices = discoverServices
        self.discoverCharacteristics = discoverCharacteristics
        self.readCharacteristic = readCharacteristic
    }
}

extension RequestClient {
    public static let testValue = RequestClient(
        enable: { fatalError("Not implemented") },
        disable: { fatalError("Not implemented") },
        startScanning: { _ in fatalError("Not implemented") },
        stopScanning: { fatalError("Not implemented") },
        connect: { _ in fatalError("Not implemented") },
        disconnect: { _ in fatalError("Not implemented") },
        discoverServices: { _, _ in fatalError("Not implemented") },
        discoverCharacteristics: { _, _ in fatalError("Not implemented") },
        readCharacteristic: { _, _, _, _ in fatalError("Not implemented") }
    )
}
