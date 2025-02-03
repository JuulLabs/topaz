import Bluetooth
import BluetoothClient
import Foundation

extension Options {
    func includeAdvertisementEventInDeviceList(_ advertisementEvent: AdvertisementEvent) -> Bool {
        guard acceptAllDevices == false else {
            return true
        }

        let matchesOnFilters = self.filters?.compactMap { $0.matches(with: advertisementEvent) }.contains { $0 == true } ?? true

        let matchesOnExclusionFilters = self.exclusionFilters?.compactMap { $0.matches(with: advertisementEvent) }.contains { $0 == true } ?? false

        return matchesOnFilters && !matchesOnExclusionFilters
    }
}

extension Options.Filter {
    func matches(with advertisementEvent: AdvertisementEvent) -> Bool {

        let advertisedServices = advertisementEvent.advertisement.serviceUUIDs
        var filterChecks = FilterChecks(filter: self)

        if let filteredServices = self.services?.compactMap({ $0 }), advertisedServices.contains(filteredServices) {
            filterChecks.servicesMatch = true
        }

        if let localName = advertisementEvent.advertisement.localName, self.name == localName {
            filterChecks.namesMatch = true
        }

        if let localName = advertisementEvent.advertisement.localName, let namePrefix = self.namePrefix, localName.hasPrefix(namePrefix) {
            filterChecks.prefixedNamesMatch = true
        }

        if let manufacturerData = advertisementEvent.advertisement.manufacturerData, self.manufacturerData?.compactMap({ $0.matches(with: manufacturerData) }).allSatisfy({ $0 == true }) ?? true {
            filterChecks.manufacturerDatumMatch = true
        }

        if self.serviceData?.compactMap({ $0.matches(with: advertisementEvent.advertisement.serviceData) }).allSatisfy({ $0 == true }) ?? true {
            filterChecks.serviceDatumMatch = true
        }

        return filterChecks.matchesFilter()
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

private struct FilterChecks {
    var servicesMatch: Bool?
    var namesMatch: Bool?
    var prefixedNamesMatch: Bool?
    var manufacturerDatumMatch: Bool?
    var serviceDatumMatch: Bool?

    init(filter: Options.Filter) {
        servicesMatch = initCheck(shouldBeEnabled: filter.services != nil)
        namesMatch = initCheck(shouldBeEnabled: filter.name != nil)
        prefixedNamesMatch = initCheck(shouldBeEnabled: filter.namePrefix != nil)
        manufacturerDatumMatch = initCheck(shouldBeEnabled: filter.manufacturerData != nil)
        serviceDatumMatch = initCheck(shouldBeEnabled: filter.serviceData != nil)
    }

    func matchesFilter() -> Bool {
        for child in Mirror(reflecting: self).children {
            if let check = child.value as? Bool {
                guard check else {
                    return false
                }
            }
        }

        return true
    }

    private func initCheck(shouldBeEnabled: Bool) -> Bool? {
        // If the filter has a non-nil field, we should check against this filter--starting
        // by assuming the check will fail. Otherwise, set the check to nil, as we will not
        // check on it.
        return shouldBeEnabled ? false : nil
    }
}
