import Bluetooth
import BluetoothClient
import Foundation

extension Options {
    func includeAdvertisementEventInDeviceList(_ advertisementEvent: AdvertisementEvent) -> Bool {
        guard acceptAllDevices == false else {
            return true
        }

        let advertisement = advertisementEvent.advertisement

        let matchesOnFilters = self.filters?.contains { $0.matches(with: advertisement) } ?? true

        let matchesOnExclusionFilters = self.exclusionFilters?.contains { $0.matches(with: advertisement) } ?? false

        return matchesOnFilters && !matchesOnExclusionFilters
    }
}

extension Options.Filter {
    func matches(with advertisement: Advertisement) -> Bool {

        if let services, !advertisement.serviceUUIDs.contains(services) {
            return false
        }

        if let name, name != advertisement.localName {
            return false
        }

        if let namePrefix {
            guard advertisement.localName?.hasPrefix(namePrefix) == true else {
                return false
            }
        }

        if let manufacturerData {
            guard manufacturerData.allSatisfy({ advertisement.manufacturerData.map($0.matches) ?? false }) else {
                return false
            }
        }

        if let serviceData, !serviceData.allSatisfy({ $0.matches(with: advertisement.serviceData) }) {
            return false
        }

        return true
    }
}

extension Options.Filter.ManufacturerData {
    func matches(with advertisedManufacturerData: ManufacturerData) -> Bool {
        guard self.companyIdentifier == advertisedManufacturerData.code else {
            return false
        }

        return advertisedManufacturerData.data.matches(with: self.dataPrefix, using: self.mask)
    }
}

extension Options.Filter.ServiceData {
    func matches(with advertisedServiceData: ServiceData) -> Bool {
        // Ensures the UUID from the filter is in the advertisedData
        guard let advertisedData = advertisedServiceData.data(for: self.service) else {
            return false
        }

        return advertisedData.matches(with: self.dataPrefix, using: self.mask)
    }
}

extension Data {
    func matches(with dataPrefix: [UInt8]?, using mask: [UInt8]?) -> Bool {
        guard let dataPrefix else {
            return true
        }
        guard let mask else {
            return starts(with: dataPrefix)
        }
        return zip(mask, dataPrefix).map { $0.0 & $0.1 } == zip(mask, self).map { $0.0 & $0.1 }
    }
}
