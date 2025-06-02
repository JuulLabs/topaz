import Foundation

extension UUID {
    /// Create a UUID with an unsigned decimal representaiton of n in the last quartet
    /// Large values of n are clamped at 2^32 == 4,294,967,295
    /// Some hex digits are included in the higher bytes to exercise case-sensitiviy requirements
    public init(n: Int) {
        let numStr = UInt32(clamping: n).description
        let padCount = max(0, 12 - numStr.count)
        let prefix = String(repeating: "0", count: padCount)
        self.init(uuidString: "00000000-0000-BEEF-cafe-" + prefix + numStr)!
    }
}
