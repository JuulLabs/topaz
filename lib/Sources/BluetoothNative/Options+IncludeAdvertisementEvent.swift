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

        if let services = self.services {
            if !advertisement.serviceUUIDs.contains(services) {
                return false
            }
        }

        if let name = self.name {
            if name != advertisement.localName {
                return false
            }
        }

        if let namePrefix = self.namePrefix {
            guard let advertisementLocalName = advertisement.localName else {
                return false
            }
            if !advertisementLocalName.hasPrefix(namePrefix) {
                return false
            }
        }

        if let manufacturerData = self.manufacturerData {
            guard let advertisementManufacturerData = advertisement.manufacturerData else {
                return false
            }
            if !manufacturerData.allSatisfy({ $0.matches(with: advertisementManufacturerData) }) {
                return false
            }
        }

        if let serviceData = self.serviceData {
            if !serviceData.allSatisfy({ $0.matches(with: advertisement.serviceData) }) {
                return false
            }
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
        if let dataPrefix = dataPrefix {

            if let mask = mask {
                return zip(mask, dataPrefix).compactMap { $0.0 & $0.1 } == zip(mask, self).compactMap { $0.0 & $0.1 }
            }

            return self.starts(with: dataPrefix)
        }

        return true
    }
}
