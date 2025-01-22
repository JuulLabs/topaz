import Foundation

extension Task where Success == Never, Failure == Never {
    public static func bigYield() async {
        try? await sleep(nanoseconds: NSEC_PER_SEC / 1000)
    }
}
