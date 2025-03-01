import Foundation

// https://webbluetoothcg.github.io/web-bluetooth/scanning.html#scan-control
public struct BluetoothLEScan: Sendable {
    public let filters: [Options.Filter]
    public let keepRepeatedDevices: Bool
    public let acceptAllAdvertisements: Bool
    public let active: Bool

    public init(filters: [Options.Filter], keepRepeatedDevices: Bool, acceptAllAdvertisements: Bool, active: Bool) {
        self.filters = filters
        self.keepRepeatedDevices = keepRepeatedDevices
        self.acceptAllAdvertisements = acceptAllAdvertisements
        self.active = active
    }

    public func toFilterOptions() -> Options {
        acceptAllAdvertisements ? Options(acceptAllDevices: true) : Options(filters: filters)
    }
}
