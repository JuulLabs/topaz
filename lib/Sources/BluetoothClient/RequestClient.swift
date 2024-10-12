import Bluetooth
import Foundation

public struct RequestClient: Sendable {
    public var enable: @Sendable () -> SystemState
    public var disable: @Sendable () -> Void
    public var state: @Sendable () -> AsyncStream<SystemState>
    public var scan: @Sendable (Filter) -> AsyncStream<Advertisement>
    public var scannedPeripheral: @Sendable (UUID) -> AnyPeripheral?
    public var connect: @Sendable (AnyPeripheral) -> Void
    public var disconnect: @Sendable (AnyPeripheral) -> Void
    public var discoverServices: @Sendable (AnyPeripheral, ServiceDiscoveryFilter) -> Void
    public var discoverCharacteristics: @Sendable (AnyPeripheral, CharacteristicDiscoveryFilter) -> Void

    public init(
        enable: @Sendable @escaping () -> SystemState,
        disable: @Sendable @escaping () -> Void,
        state: @Sendable @escaping () -> AsyncStream<SystemState>,
        scan: @Sendable @escaping (Filter) -> AsyncStream<Advertisement>,
        scannedPeripheral: @Sendable @escaping (UUID) -> AnyPeripheral?,
        connect: @Sendable @escaping (AnyPeripheral) -> Void,
        disconnect: @Sendable @escaping (AnyPeripheral) -> Void,
        discoverServices: @Sendable @escaping (AnyPeripheral, ServiceDiscoveryFilter) -> Void,
        discoverCharacteristics: @Sendable @escaping (AnyPeripheral, CharacteristicDiscoveryFilter) -> Void
    ) {
        self.enable = enable
        self.disable = disable
        self.state = state
        self.scan = scan
        self.scannedPeripheral = scannedPeripheral
        self.connect = connect
        self.disconnect = disconnect
        self.discoverServices = discoverServices
        self.discoverCharacteristics = discoverCharacteristics
    }
}

extension RequestClient {
    public static let testValue = RequestClient(
        enable: { fatalError("Not implemented") },
        disable: { fatalError("Not implemented") },
        state: { fatalError("Not implemented") },
        scan: { _ in fatalError("Not implemented") },
        scannedPeripheral: { _ in fatalError("Not implemented") },
        connect: { _ in fatalError("Not implemented") },
        disconnect: { _ in fatalError("Not implemented") },
        discoverServices: { _, _ in fatalError("Not implemented") },
        discoverCharacteristics: { _, _ in fatalError("Not implemented") }
    )
}
