#if targetEnvironment(simulator)
import Foundation

// TODO: move to a "Fakes" module

public struct FakePeripheral: PeripheralProtocol {
    public let identifier: UUID
    public let name: String?
    public var connectionState: Bluetooth.ConnectionState = .disconnected

    public init(
        name: String,
        connectionState: Bluetooth.ConnectionState = .disconnected,
        identifier: UUID? = nil
    ) {
        self.name = name
        self.connectionState = connectionState
        self.identifier = identifier ?? UUID()
    }
}

extension FakePeripheral {
    public func fakeAd(rssi: Int) -> Advertisement {
        Advertisement(
            peripheralId: identifier,
            peripheralName: name,
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
