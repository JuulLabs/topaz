import Bluetooth
import Foundation
import JsMessage


//filter based on services with Filter's UUIDs property

//extension Filter {
//    // TODO: all the filter kinds https://juullabs.atlassian.net/browse/CA-3822
//    static func decode(from data: [String: JsType]?) -> Self {
//        let rawFilters = data?["filters"]?.array
//        let serviceFilters = rawFilters?.compactMap { $0.dictionary?["services"] }
//        let serviceUuids = serviceFilters?.compactMap { $0.string }.compactMap { UUID(uuidString: $0) }
//        return Filter(services: serviceUuids ?? [])
//    }
//}


private let filtersKey = "filters"
private let servicesKey = "services"
private let nameKey = "name"
private let namePrefixKey = "namePrefix"
private let manufacturerDataKey = "manufacturerData"
private let companyIdentifierKey = "companyIdentifier"
private let dataPrefixKey = "dataPrefix"
private let maskKey = "mask"
private let serviceDataKey = "serviceData"
private let serviceKey = "service"
private let exclusionFiltersKey = "exclusionFilters"
private let optionalServicesKey = "optionalServices"
private let optionalManufacturerDataKey = "optionalManufacturerData"
private let acceptAllDevicesKey = "acceptAllDevices"

extension Options {

    // { filters: [ {services: ["some-service-uuid", "another-uuid"]} ] }
    static func decode(from data: [String: JsType]?) throws -> Self {
//        let allFilters = data?[filtersKey]?.array

//        // Service Filters
//        let serviceFilterUuids = allFilters?.compactMap { $0.dictionary?[servicesKey]?.array }.compactMap { $0.compactMapToUUIDs() }
//        let serviceFilters = serviceFilterUuids?.compactMap { Options.Filter(services: $0) }//.nilIfEmpty()
//
//        // Name Filters
//        let nameFilters = allFilters?.compactMap { $0.dictionary?[nameKey]?.string }.compactMap { Options.Filter(name: $0) }
//
//        // NamePrefix Filters
//        let namePrefixFilters = allFilters?.compactMap { $0.dictionary?[namePrefixKey]?.string }.compactMap { Options.Filter(namePrefix: $0) }
//

        let filters = try data?[filtersKey]?.array?.compactMap { try Options.Filter.decode(from: $0.dictionary) }.nilIfEmpty()
        let exclusionFilters = try data?[exclusionFiltersKey]?.array?.compactMap { try Options.Filter.decode(from: $0.dictionary) }

//        // Optional Services
        let optionalServices = data?[optionalServicesKey]?.array?.compactMapToUUIDs()

        let optionalManufacturerData = data?[optionalManufacturerDataKey]?.array?.compactMapToUint16Array()

        let acceptAllDevices = data?[acceptAllDevicesKey]?.number?.boolValue

        // Empty input provided
        guard filters != nil || exclusionFilters != nil || optionalServices != nil || optionalManufacturerData != nil || acceptAllDevices != nil else {
            throw OptionsError.invalidInput
        }

        // Cannot set acceptAllDevicesTo true if other options are provided
        if acceptAllDevices == true {
            guard filters == nil && exclusionFilters == nil && optionalServices == nil && optionalManufacturerData == nil else {
                throw OptionsError.invalidInput
            }
        }

        if exclusionFilters != nil {
            // Cannot use exclusionFilters without filters
            guard filters != nil else {
                throw OptionsError.invalidInput
            }

            // If exclusionFilters is provided, it cannot be empty
            guard exclusionFilters?.isEmpty == false else {
                throw OptionsError.invalidInput
            }
        }
//
//        let gatheredFilters: [Options.Filter]? = [serviceFilters, nameFilters, namePrefixFilters].compactMap { $0 }.flatMap { $0 }.nilIfEmpty()

        return Options(filters: filters, exclusionFilters: exclusionFilters, optionalServices: optionalServices, optionalManufacturerData: optionalManufacturerData, acceptAllDevices: acceptAllDevices)
    }
}

// { filters: [ {services: [C], namePrefix: "Device"}, {name: "Unique Name"} ] }
extension Options.Filter {
    static func decode(from data: [String: JsType]?) throws -> Self? {
        // Services
        let services = data?[servicesKey]?.array?.compactMapToUUIDs()

        // Name
        let name = data?[nameKey]?.string

        // NamePrefix
        let namePrefix = data?[namePrefixKey]?.string

        // namePrefix cannot be an empty string
        guard namePrefix != "" else {
            throw OptionsError.invalidInput
        }

        // ManufacturerData
        let manufacturerDataFilters = data?[manufacturerDataKey]?.array?.compactMap { Options.Filter.ManufacturerData.decode(from: $0.dictionary) }

        // manufacturerData, if provided, cannot be empty
        if let manufacturerDataFilters = manufacturerDataFilters {
            guard manufacturerDataFilters.isEmpty == false else {
                throw OptionsError.invalidInput
            }
        }

        // ServiceData
        let serviceDataFilters = data?[serviceDataKey]?.array?.compactMap { Options.Filter.ServiceData.decode(from: $0.dictionary) }

        // serviceData, if provided, cannot be empty
        if let serviceDataFilters = serviceDataFilters {
            guard serviceDataFilters.isEmpty == false else {
                throw OptionsError.invalidInput
            }
        }

        guard services?.isEmpty == false || name != nil || namePrefix != nil || manufacturerDataFilters?.isEmpty == false || serviceDataFilters?.isEmpty == false else {
            return nil
        }

        return Options.Filter(services: services, name: name, namePrefix: namePrefix, manufacturerData: manufacturerDataFilters, serviceData: serviceDataFilters)
    }
}

extension Options.Filter.ManufacturerData {
    static func decode(from data: [String: JsType]?) -> Self? {
        guard let companyIdentifier = data?[companyIdentifierKey]?.number?.uint16Value else {
            return nil
        }

        let dataPrefix = data?[dataPrefixKey]?.array?.compactMapToUint8Array()

        let mask = data?[maskKey]?.array?.compactMapToUint8Array()

        return Options.Filter.ManufacturerData(companyIdentifier: companyIdentifier, dataPrefix: dataPrefix, mask: mask)
    }
}

extension Options.Filter.ServiceData {
    static func decode(from data: [String: JsType]?) -> Self? {
        guard let service = data?[serviceKey]?.string.toUuid() else {
            return nil
        }

        let dataPrefix = data?[dataPrefixKey]?.array?.compactMapToUint8Array()

        let mask = data?[maskKey]?.array?.compactMapToUint8Array()

        return Options.Filter.ServiceData(service: service, dataPrefix: dataPrefix, mask: mask)
    }
}

extension [JsType] {

    func compactMapToUUIDs() -> [UUID]? {
        self.compactMap { $0.string.toUuid() }
    }

    func compactMapToUint8Array() -> [UInt8]? {
        self.compactMap { $0.number }.compactMap { UInt8(truncating: $0) }
    }

    func compactMapToUint16Array() -> [UInt16]? {
        self.compactMap { $0.number }.compactMap { UInt16(truncating: $0) }
    }
}

extension String? {
    func toUuid() -> UUID? {
        guard let self = self else {
            return nil
        }
        return UUID(uuidString: self) // TODO: Properly convert to special UUIDs
    }
}

extension [Options.Filter] {
    func nilIfEmpty() -> [Options.Filter]? {
        guard self.isEmpty == false else {
            return nil
        }
        return self
    }
}

//        let serviceFilters = allFilters?.flatMap { $0.dictionary?[servicesKey]?.array ?? [] }
//        let serviceUuids = serviceFilters?.compactMap { $0.string }.compactMap { UUID(uuidString: $0) } // TODO: Properly convert to special UUIDs

        // Service Filters
//        let serviceFilters = allFilters?.compactMap { $0.dictionary?[servicesKey]?.array }.first
//        let serviceUuids = serviceFilters?.compactMap { $0.string }

//        let thing = Options.Filter(services: serviceUuids)
