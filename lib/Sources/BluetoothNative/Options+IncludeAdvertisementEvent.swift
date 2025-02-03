import Bluetooth
import BluetoothClient
import Foundation

extension Options {
    func includeAdvertisementEventInDeviceList(_ advertisementEvent: AdvertisementEvent) -> Bool {

//        let advertisedServices = advertisementEvent.advertisement.serviceUUIDs

        guard acceptAllDevices == false else {
            return true
        }

        let matchesOnFilters = self.filters?.compactMap { $0.matches(with: advertisementEvent) }.reduce(false, { partialResult, next in partialResult || next }) ?? true

        let matchesOnExclusionFilters = self.exclusionFilters?.compactMap { $0.matches(with: advertisementEvent) }.reduce(false, { partialResult, next in partialResult || next }) ?? false

        return matchesOnFilters && !matchesOnExclusionFilters

//        for filter in self.filters ?? [] {
//
//
//            filter.matches(with: advertisementEvent)

//            var filterChecks = FilterChecks(filter: filter)
//
//            if let filteredServices = filter.services?.compactMap({ $0 }), advertisedServices.contains(filteredServices) {
//                filterChecks.servicesMatch = true
//            }
//
//            if let localName = advertisementEvent.advertisement.localName, filter.name == localName {
//                filterChecks.namesMatch = true
//            }
//
//            if let localName = advertisementEvent.advertisement.localName, let namePrefix = filter.namePrefix, localName.hasPrefix(namePrefix) {
//                filterChecks.prefixedNamesMatch = true
//            }
//
//            if filterChecks.matchesFilter() {
//                return true
//            }

//            return servicesMatch && namesMatch
//        }

//        let advertisedServices = advertisementEvent.peripheral.services.map { $0.uuid }

//        let serviceFilters = self.filters?.compactMap { $0.services?.compactMap { $0 } } ?? []
//
//        for serviceFilter in serviceFilters {
//            if advertisedServices.contains(serviceFilter) {
//                return true
//            }
//        }

//        if let filters = self.filters, let localName = advertisementEvent.advertisement.localName, filters.contains(where: { $0.name == localName }) {
//            return true
//        }

//        if let filters = self.filters, let localName = advertisementEvent.advertisement.localName, filters.contains(where: {
//            guard let namePrefix = $0.namePrefix else {
//                return false
//            }
//            return localName.hasPrefix(namePrefix)
//        }) {
//            return true
//        }

//        return matchesOnFilters
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

        if let manufacturerData = advertisementEvent.advertisement.manufacturerData, self.manufacturerData?.compactMap({ $0.matches(with: manufacturerData) }).reduce(true, { partial, next in partial && next }) ?? true {
            filterChecks.manufacturerDatumMatch = true
        }

        if self.serviceData?.compactMap({ $0.matches(with: advertisementEvent.advertisement.serviceData) }).reduce(true, { partial, next in partial && next}) ?? true {
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


//        if let dataPrefix = self.dataPrefix {
//
////            let balls = advertisedManufacturerData.data & self.mask
////            for byte in advertisedManufacturerData.data {
////                let but = byte & (self.mask?[0])!
////            }
//
//            if let mask = self.mask {
////                for i in 0..<mask.count {
////                    let anded = advertisedManufacturerData.data[i] & mask[i]
////                    let twod = dataPrefix[i] & mask[i]
////                    print(anded)
////                    print(twod)
////                }
//
//                let a = zip(mask, dataPrefix).compactMap { $0.0 & $0.1 }
//                let b = zip(mask, advertisedManufacturerData.data).compactMap { $0.0 & $0.1 }
//
//                return zip(mask, dataPrefix).compactMap { $0.0 & $0.1 } == zip(mask, advertisedManufacturerData.data).compactMap { $0.0 & $0.1 }
//            }
//
//
//
//            return advertisedManufacturerData.data.starts(with: dataPrefix)
//
////            let balls = Data(dataPrefix).compactMap { $0 as? UInt8 }
////
////            for i in 0..<Data(dataPrefix).count {
////                
////            }
////
////            for byte in Data(dataPrefix) {
////
////            }
////            return advertisedManufacturerData.data == Data(dataPrefix)
//        }
//
//        return true
    }
}

extension Options.Filter.ServiceData {
    func matches(with advertisedServiceData: ServiceData) -> Bool {

        // Ensures the UUID from the filter is in the advertisedData
        guard let advertisedData = advertisedServiceData.data(for: self.service) else {
            return false
        }

        return advertisedData.matches(with: self.dataPrefix, using: self.mask)

//        if let dataPrefix = self.dataPrefix {
//
//            if let mask = self.mask {
//                return zip(mask, dataPrefix).compactMap { $0.0 & $0.1 } == zip(mask, advertisedData).compactMap { $0.0 & $0.1 }
//            }
//
//            return advertisedData.starts(with: dataPrefix)
//        }
//
//        return true
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

//private func match(advertisedData: Data, with dataPrefix: [UInt8]?, using mask: [UInt8]?) -> Bool {
//    if let dataPrefix = dataPrefix {
//
//        if let mask = mask {
//            return zip(mask, dataPrefix).compactMap { $0.0 & $0.1 } == zip(mask, advertisedData).compactMap { $0.0 & $0.1 }
//        }
//
//        return advertisedData.starts(with: dataPrefix)
//    }
//
//    return true
//}

private struct FilterChecks {
    var servicesMatch: Bool? = nil
    var namesMatch: Bool? = nil
    var prefixedNamesMatch: Bool? = nil
    var manufacturerDatumMatch: Bool? = nil
    var serviceDatumMatch: Bool? = nil

    init(filter: Options.Filter) {

        if let _ = filter.services {
            servicesMatch = false
        }

        if let _ = filter.name {
            namesMatch = false
        }

        if let _ = filter.namePrefix {
            prefixedNamesMatch = false
        }

        if let _ = filter.manufacturerData {
            manufacturerDatumMatch = false
        }

        if let _ = filter.serviceData {
            serviceDatumMatch = false
        }
    }

    func matchesFilter() -> Bool {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if let check = child.value as? Bool {
                guard check else {
                    return false
                }
            }
        }

        return true
    }
}

// investigate this option. might be cleaner
extension Options.Filter {
    var servicesMatch: Bool? {
        if self.services != nil {
            return false
        }
        return nil
    }
}
