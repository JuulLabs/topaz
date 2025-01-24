@testable import Helpers
import Foundation
import TestHelpers
import Testing

struct DeferredValueTests {

    @Test
    func getValue_initializedWithNilValue_waitsForNonNilValue() async {
        let sut = DeferredValue<String>(initialValue: nil)
        let task = Task {
            await sut.getValue()
        }
        await Task.bigYield()
        await sut.setValue("Hello")
        let value = await task.value
        #expect(value == "Hello")
    }

    @Test
    func getValue_initializedWithNonNilValue_emitsValueImmediately() async {
        let sut = DeferredValue<String>(initialValue: "Hello")
        let value = await sut.getValue()
        #expect(value == "Hello")
    }

    @Test
    func getValue_initializedWithNonNilValueAndThenUpdated_emitsInitialValueAndThenNewValue() async {
        let sut = DeferredValue<String>(initialValue: "Hello")
        let task = Task {
            await sut.getValue()
        }
        await Task.bigYield()
        await sut.setValue("Bye")
        let value = await task.value
        #expect(value == "Hello")
        let newValue = await sut.getValue()
        #expect(newValue == "Bye")
    }

    @Test
    func getValue_initializedWithNilValueAndThenCancelled_emitsNil() async {
        let sut = DeferredValue<String>(initialValue: nil)
        let task = Task {
            await sut.getValue()
        }
        await Task.bigYield()
        task.cancel()
        let value = await task.value
        #expect(value == nil)
    }

    @Test
    func getValue_initializedWithNonNilValueAndThenCancelled_emitsValue() async {
        let sut = DeferredValue<String>(initialValue: "Hello")
        let task = Task {
            await sut.getValue()
        }
        task.cancel()
        let value = await task.value
        #expect(value == "Hello")
    }
}
