import Bluetooth
import Foundation

public protocol DelEvent: Sendable {
    var key: EventKey { get }
}
