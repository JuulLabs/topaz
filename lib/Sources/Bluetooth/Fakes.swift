#if targetEnvironment(simulator)
import Foundation
import Helpers

// TODO: move to a "Fakes" module

private class MockPeripheralProtocol: PeripheralProtocol {
    let connectionState: ConnectionState
    let isReadyToSendWriteWithoutResponse: Bool

    init(connectionState: ConnectionState, isReadyToSendWriteWithoutResponse: Bool = true) {
        self.connectionState = connectionState
        self.isReadyToSendWriteWithoutResponse = isReadyToSendWriteWithoutResponse
    }
}

public func FakePeripheral(
    id: UUID,
    connectionState: ConnectionState = .disconnected,
    name: String? = nil,
    services: [Service] = []
) -> Peripheral {
    Peripheral(
        peripheral: AnyProtectedObject(wrapping: MockPeripheralProtocol(connectionState: connectionState), in: NonLockingStrategy()),
        id: id,
        name: name,
        services: services
    )
}

extension Peripheral {
    public func fakeAd(rssi: Int) -> Advertisement {
        Advertisement(
            peripheralId: id,
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

public func FakeService(
    uuid: UUID,
    isPrimary: Bool = true,
    characteristics: [Characteristic] = []
) -> Service {
    Service(
        service: AnyProtectedObject(wrapping: NSObject(), in: NonLockingStrategy()),
        uuid: uuid,
        isPrimary: isPrimary,
        characteristics: characteristics)
}

public func FakeCharacteristic(
    uuid: UUID,
    instance: UInt32 = 0,
    properties: CharacteristicProperties = [],
    value: Data? = nil,
    isNotifying: Bool = false,
    descriptors: [Descriptor] = []
) -> Characteristic {
    Characteristic(
        characteristic: AnyProtectedObject(wrapping: NSObject(), in: NonLockingStrategy()),
        uuid: uuid,
        instance: instance,
        properties: properties,
        value: value,
        isNotifying: isNotifying,
        descriptors: descriptors
    )
}

#endif
