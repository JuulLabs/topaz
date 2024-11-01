#if targetEnvironment(simulator)
import Foundation

// TODO: move to a "Fakes" module

public struct FakePeripheral: Equatable, WrappedPeripheral {
    public let _identifier: UUID
    public let _name: String?
    public var _connectionState: ConnectionState = .disconnected
    public var _services: [Service]

    public init(
        name: String,
        connectionState: ConnectionState = .disconnected,
        identifier: UUID? = nil,
        services: [Service] = []
    ) {
        self._name = name
        self._connectionState = connectionState
        self._identifier = identifier ?? UUID()
        self._services = services
    }
}

extension FakePeripheral {
    public func fakeAd(rssi: Int) -> Advertisement {
        Advertisement(
            peripheralId: _identifier,
            peripheralName: _name,
            rssi: rssi,
            isConnectable: nil,
            localName: nil,
            manufacturerData: nil,
            overflowServiceUUIDs: [],
            serviceData: ServiceData([:]),
            serviceUUIDs: [],
            solicitedServiceUUIDs: [],
            txPowerLevel: nil
        )
    }
}
#endif
