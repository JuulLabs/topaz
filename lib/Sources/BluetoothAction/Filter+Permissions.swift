import Bluetooth
import Foundation
import SecurityList

/*
 * Per https://webbluetoothcg.github.io/web-bluetooth/#device-discovery
 * > In rare cases, a device may not advertise enough distinguishing information to let a
 * > site filter out uninteresting devices. In those cases, a site can set acceptAllDevices
 * > to true and omit all filters and exclusionFilters. This puts the burden of selecting
 * > the right device entirely on the site’s users. If a site uses acceptAllDevices, it will
 * > only be able to use services listed in optionalServices.
 *
 * > After the user selects a device to pair with this origin, the origin is allowed to access
 * > any service whose UUID was listed in the services list in any element of options.filters
 * > or in options.optionalServices. The origin is also allowed to access any manufacturer data
 * > from manufacturer codes defined in options.optionalManufacturerData from the device’s
 * > advertisement data.
 *
 * > This implies that if developers filter just by name, they must use optionalServices to get
 * > access to any services.
 *
 * And elsewhere, the documentation for parsing filter options states:
 * > Remove from optionalServiceUUIDs any UUIDs that are blocklisted
 *
 * The inference here is that the blocklist is applied to optionalServices/optionalManufacturerData
 * by dint of the parser implementation. The intended effect is that advertisements and discovery
 * would silently strip out such elements later on due to the filter logic.
 */

extension Options {
    /**
     Create restricted permissions set to be applied when using the interactive device picker.
     */
    func toRestrictivePermissions() -> PeripheralPermissions {
        let services = Set(allServiceUuids() + (optionalServices ?? []))
        return PeripheralPermissions(allowedServices: .restricted(services))
    }
}

/**
 * Check the given list of filters against the blocklist and throw an error if there is a match.
 */
func checkFiltersAreAllowed(securityList: SecurityList, filters: [Options.Filter]) throws {
    try filters.forEach { filter in
        try filter.services?.forEach { service in
            if securityList.isBlocked(service, in: .services) {
                throw BluetoothError.blocklisted(service)
            }
        }
        try filter.serviceData?.forEach { serviceData in
            if securityList.isBlocked(serviceData.service, in: .services) {
                throw BluetoothError.blocklisted(serviceData.service)
            }
        }
        // TODO: check manufacturerData blocklist
    }
}
