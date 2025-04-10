import Bluetooth
import Foundation
import JsMessage

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
    static func decode(from data: [String: JsType]?) throws -> Self {
        let filters = try data?[filtersKey]?.array?.compactMap { try Options.Filter.decode(from: $0.dictionary) }.nilIfEmpty()
        let exclusionFilters = try data?[exclusionFiltersKey]?.array?.compactMap { try Options.Filter.decode(from: $0.dictionary) }
        let optionalServices = data?[optionalServicesKey]?.array?.compactMapToUUIDs()
        let optionalManufacturerData = data?[optionalManufacturerDataKey]?.dictionary?.compactMapToUint16Array()
        let acceptAllDevices = data?[acceptAllDevicesKey]?.number?.boolValue ?? false

        guard filters != nil || exclusionFilters != nil || optionalServices != nil || optionalManufacturerData != nil || acceptAllDevices else {
            throw OptionsError.invalidInput("Empty options provided")
        }

        if acceptAllDevices == true {
            guard filters == nil && exclusionFilters == nil && optionalManufacturerData == nil else {
                throw OptionsError.invalidInput("Cannot set acceptAllDevices to true if other options are provided")
            }
        }

        if exclusionFilters != nil {
            guard filters != nil else {
                throw OptionsError.invalidInput("Cannot use exclusionFilters without filters")
            }

            guard exclusionFilters?.isEmpty == false else {
                throw OptionsError.invalidInput("If exclusionFilters is provided, it cannot be empty")
            }
        }

        return Options(filters: filters, exclusionFilters: exclusionFilters, optionalServices: optionalServices, optionalManufacturerData: optionalManufacturerData, acceptAllDevices: acceptAllDevices)
    }
}

extension Options.Filter {
    static func decode(from data: [String: JsType]?) throws -> Self? {
        let services = data?[servicesKey]?.array?.compactMapToUUIDs()
        let name = data?[nameKey]?.string
        let namePrefix = data?[namePrefixKey]?.string

        guard namePrefix != "" else {
            throw OptionsError.invalidInput("namePrefix cannot be an empty string")
        }

        let manufacturerDataFilters = try data?[manufacturerDataKey]?.array?.compactMap { try Options.Filter.ManufacturerData.decode(from: $0.dictionary) }

        if let manufacturerDataFilters = manufacturerDataFilters {
            guard manufacturerDataFilters.isEmpty == false else {
                throw OptionsError.invalidInput("manufacturerData, if provided, cannot be empty")
            }
        }

        let serviceDataFilters = try data?[serviceDataKey]?.array?.compactMap { try Options.Filter.ServiceData.decode(from: $0.dictionary) }

        if let serviceDataFilters = serviceDataFilters {
            guard serviceDataFilters.isEmpty == false else {
                throw OptionsError.invalidInput("serviceData, if provided, cannot be empty")
            }
        }

        guard services?.isEmpty == false || name != nil || namePrefix != nil || manufacturerDataFilters?.isEmpty == false || serviceDataFilters?.isEmpty == false else {
            return nil
        }

        return Options.Filter(services: services, name: name, namePrefix: namePrefix, manufacturerData: manufacturerDataFilters, serviceData: serviceDataFilters)
    }
}

extension Options.Filter.ManufacturerData {
    static func decode(from data: [String: JsType]?) throws -> Self? {
        guard let companyIdentifier = data?[companyIdentifierKey]?.number?.uint16Value else {
            return nil
        }

        let dataPrefix = data?[dataPrefixKey]?.dictionary?.compactMapToUint8Array()

        let mask = data?[maskKey]?.dictionary?.compactMapToUint8Array()

        if mask != nil {
            guard dataPrefix != nil else {
                throw OptionsError.invalidInput("manufacturerData.mask, if provided, must also have a dataPrefix")
            }
        }

        return Options.Filter.ManufacturerData(companyIdentifier: companyIdentifier, dataPrefix: dataPrefix, mask: mask)
    }
}

extension Options.Filter.ServiceData {
    static func decode(from data: [String: JsType]?) throws -> Self? {
        guard let service = data?[serviceKey]?.string.toUuid() else {
            return nil
        }

        let dataPrefix = data?[dataPrefixKey]?.dictionary?.compactMapToUint8Array()

        let mask = data?[maskKey]?.dictionary?.compactMapToUint8Array()

        if mask != nil {
            guard dataPrefix != nil else {
                throw OptionsError.invalidInput("serviceData.mask, if provided, must also have a dataPrefix")
            }
        }

        return Options.Filter.ServiceData(service: service, dataPrefix: dataPrefix, mask: mask)
    }
}

extension [JsType] {
    func compactMapToUUIDs() -> [UUID]? {
        self.compactMap { $0.string.toUuid() }
    }
}

extension Dictionary where Key == String, Value == JsType {
    func compactMapToUint8Array() -> [UInt8]? {
        self.sorted(by: { $0.key < $1.key }).compactMap { $0.value.number.map(UInt8.init(truncating:)) }
    }

    func compactMapToUint16Array() -> [UInt16]? {
        self.sorted(by: { $0.key < $1.key }).compactMap { $0.value.number.map(UInt16.init(truncating:)) }
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
