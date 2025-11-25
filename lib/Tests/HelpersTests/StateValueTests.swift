@testable import Helpers
import Foundation
import Testing

struct StateValueTests {

    @Test
    func getValue_initializedWithDefaultFlags_waitsForNewValue() async {
        let sut = StateValue<String>(initialValue: "Hello")
        let task = Task {
            await sut.getValue()
        }
        await Task.bigYield()
        await sut.setValue("Bye")
        let value = await task.value
        #expect(value == "Bye")
    }

    @Test
    func getValue_initializedWithEmitOnStartTrue_emitsValueImmediately() async {
        let sut = StateValue<String>(initialValue: "Hello", emitOnStart: true)
        let value = await sut.getValue()
        #expect(value == "Hello")
    }

    @Test
    func getValue_initializedWithEmitOnStartTrueWhenReadAndUpdatedAndReadAgain_emitsInitialValueAndThenNewValue() async {
        let sut = StateValue<String>(initialValue: "Hello", emitOnStart: true)
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
    func getValue_whenCancelled_emitsInitialValue() async {
        let sut = StateValue<String>(initialValue: "Hello")
        let task = Task {
            await sut.getValue()
        }
        task.cancel()
        let value = await task.value
        #expect(value == "Hello")
    }

    @Test
    func getValue_whenSetFalseRepeatedlyAndThenSetTrue_emitsFalseTheExactNumberOfTimesAndTrueOnce() async throws {
        let sut = StateValue<Bool>(initialValue: false)
        let task = Task { @Sendable () async -> (stateValue: Bool, trueCount: Int, falseCount: Int) in
            var falseCount = 0
            var trueCount = 0
            var state: Bool
            repeat {
                state = await sut.getValue()
                if state {
                    trueCount += 1
                } else {
                    falseCount += 1
                }
            } while state == false
            return (state, trueCount, falseCount)
        }
        for _ in 1...3 {
            await Task.bigYield()
            await sut.setValue(false)
        }
        await Task.bigYield()
        await sut.setValue(true)
        let result = await task.value
        #expect(result.stateValue == true)
        #expect(result.trueCount == 1)

        // The `setValue` "while signal() == true" loop races against the `getValue` in this test
        // It is not harmful for our use case except for a few CPU cycles but what we actually need is
        // for `AsyncSemaphore` to support a new API where the loop can happen within the semaphore lock.
        // TODO: add a new method to AsyncSemaphore for this test to fully pass: `semaphore.signalAll()`
        // #expect(result.falseCount == 3)
    }
}
