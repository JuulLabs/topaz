import Foundation

public struct Advertisement: Equatable, Sendable {
    public let peripheralId: UUID
    public let peripheralName: String?
    public let rssi: Int
    public let isConnectable: Bool?
    public let localName: String?
    public let manufacturerData: ManufacturerData?
    public let overflowServiceUUIDs: [UUID]
    public let serviceData: ServiceData
    public let serviceUUIDs: [UUID]
    public let solicitedServiceUUIDs: [UUID]
    public let txPowerLevel: Int?

    public init(
        peripheralId: UUID,
        peripheralName: String?,
        rssi: Int,
        isConnectable: Bool?,
        localName: String?,
        manufacturerData: ManufacturerData?,
        overflowServiceUUIDs: [UUID],
        serviceData: ServiceData,
        serviceUUIDs: [UUID],
        solicitedServiceUUIDs: [UUID],
        txPowerLevel: Int?
    ) {
        self.peripheralId = peripheralId
        self.peripheralName = peripheralName
        self.rssi = rssi
        self.isConnectable = isConnectable
        self.localName = localName
        self.manufacturerData = manufacturerData
        self.overflowServiceUUIDs = overflowServiceUUIDs
        self.serviceData = serviceData
        self.serviceUUIDs = serviceUUIDs
        self.solicitedServiceUUIDs = solicitedServiceUUIDs
        self.txPowerLevel = txPowerLevel
    }
}

extension Advertisement: Identifiable {
    public var id: UUID {
        peripheralId
    }
}
