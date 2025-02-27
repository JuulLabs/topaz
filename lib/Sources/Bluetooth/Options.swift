import Foundation


public struct Options: Sendable {

    public init(
        filters: [Filter]? = nil,
        exclusionFilters: [Filter]? = nil,
        optionalServices: [UUID]? = nil,
        optionalManufacturerData: [UInt16]? = nil,
        acceptAllDevices: Bool = false
    ) {
        self.filters = filters
        self.exclusionFilters = exclusionFilters
        self.optionalServices = optionalServices
        self.optionalManufacturerData = optionalManufacturerData
        self.acceptAllDevices = acceptAllDevices
    }

    public let filters: [Filter]?
    public let exclusionFilters: [Filter]?
    public let optionalServices: [UUID]?
    public let optionalManufacturerData: [UInt16]?
    public let acceptAllDevices: Bool

    public struct Filter: Sendable {

        public init(
            services: [UUID]? = nil,
            name: String? = nil,
            namePrefix: String? = nil,
            manufacturerData: [ManufacturerData]? = nil,
            serviceData: [ServiceData]? = nil
        ) {
            self.services = services
            self.name = name
            self.namePrefix = namePrefix
            self.manufacturerData = manufacturerData
            self.serviceData = serviceData
        }

        public let services: [UUID]?
        public let name: String?
        public let namePrefix: String?
        public let manufacturerData: [ManufacturerData]?
        public let serviceData: [ServiceData]?

        public struct ManufacturerData: Sendable {

            public init(companyIdentifier: UInt16, dataPrefix: [UInt8]? = nil, mask: [UInt8]? = nil) {
                self.companyIdentifier = companyIdentifier
                self.dataPrefix = dataPrefix
                self.mask = mask
            }

            public let companyIdentifier: UInt16
            public let dataPrefix: [UInt8]?
            public let mask: [UInt8]?
        }

        public struct ServiceData: Sendable {

            public init(service: UUID, dataPrefix: [UInt8]? = nil, mask: [UInt8]? = nil) {
                self.service = service
                self.dataPrefix = dataPrefix
                self.mask = mask
            }

            public let service: UUID
            public let dataPrefix: [UInt8]?
            public let mask: [UInt8]?
        }
    }
}
