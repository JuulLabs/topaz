import Foundation

/**
 Manage access to peripheral services.

 From [Mozilla Web API docs](https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth/requestDevice):

 *After the user selects a device to pair in the current origin, it is only allowed to
 access services whose UUID was listed in the services list in any element of filters.services
 or in optionalServices.*
 */
public struct PeripheralPermissions: Sendable {
    public enum AllowedUUIDs: Sendable {
        case all
        case restricted(Set<UUID>)
    }

    public let allowedServices: AllowedUUIDs

    public init(allowedServices: AllowedUUIDs) {
        self.allowedServices = allowedServices
    }
}
