import Bluetooth
import Foundation
import JsMessage

extension Filter {
    // TODO: all the filter kinds https://juullabs.atlassian.net/browse/CA-3822
    static func decode(from data: [String: JsType]?) -> Self {
        let rawFilters = data?["filters"]?.array
        let serviceFilters = rawFilters?.compactMap { $0.dictionary?["services"] }
        let serviceUuids = serviceFilters?.compactMap { $0.string }.compactMap { UUID(uuidString: $0) }
        return Filter(services: serviceUuids ?? [])
    }
}
