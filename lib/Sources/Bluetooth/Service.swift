import Foundation

/**
 Shadows CBService
 */
public struct Service: Equatable, Sendable {
    let uuid: UUID
    let isPrimary: Bool
    let includedServices: [Service]
}
