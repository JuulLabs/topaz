@testable import Helpers
import Foundation
import Testing

@Suite("Helpers")
struct HexEncodingTests {

    @Test
    func hexEncodedString_withData_encodesByteValues() {
        let data = Data([0x01, 0x02, 0x03])
        #expect(data.hexEncodedString() == "010203")
    }

    @Test
    func hexEncodedString_withDefaultOptions_emitsLowercase() {
        let data = Data([0xca, 0xfe])
        #expect(data.hexEncodedString() == "cafe")
    }

    @Test
    func hexEncodedString_withUpperOption_emitsUppercase() {
        let data = Data([0xca, 0xfe])
        #expect(data.hexEncodedString(.upper) == "CAFE")
    }

    @Test
    func hexEncodedString_withPrefixOption_prependsPrefix() {
        let data = Data([0xbe, 0xef])
        #expect(data.hexEncodedString(.prefix) == "0xbeef")
    }

    @Test
    func hexEncodedString_withUpperAndPrefixOption_emitsUppercaseWithPrefix() {
        let data = Data([0xb0, 0xba])
        #expect(data.hexEncodedString([.prefix, .upper]) == "0xB0BA")
    }

    @Test
    func hexEncodedString_withEmptyData_isEmptyString() {
        let data = Data()
        #expect(data.hexEncodedString() == "")
    }

    @Test
    func hexEncodedString_withEmptyDataAndPrefixOption_isEmptyString() {
        let data = Data()
        #expect(data.hexEncodedString(.prefix) == "")
    }

    @Test
    func hexEncodedString_withUTF8String_encodesAsciiValues() {
        let utf8 = String("abc").utf8
        #expect(utf8.hexEncodedString() == "616263")
    }
}
