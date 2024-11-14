import Bluetooth
import BluetoothClient
import DevicePicker
import Effector
import Foundation
import Helpers
import JsMessage

/**
 Main engine - keeps state, replays web API onto native API

 TODO: lock this actor to the system Bluetooth DispatchQueue serial queue
 */
public actor BluetoothEngine: JsMessageProcessor {
    private let state: BluetoothState
    private let effector: Effector
    private let deviceSelector: InteractiveDeviceSelector
    private let client: BluetoothClient

    public init(
        state: BluetoothState,
        effector: Effector,
        deviceSelector: InteractiveDeviceSelector,
        client: BluetoothClient
    ) {
        self.state = state
        self.effector = effector
        self.deviceSelector = deviceSelector
        self.client = client
        Task {
            for await event in self.client.response.events {
                await handleDelegateEvent(event)
            }
        }
    }

    // MARK: - Bluetooth Delegate Events

    private func handleDelegateEvent(_ event: DelegateEvent) async {
        await updateState(for: event)
        await effector.ingestDelegateEvent(event)
        await sendJsEvent(for: event)
    }

    private func updateState(for event: DelegateEvent) async {
        switch event {
        case let .systemState(newState):
            await state.setSystemState(newState)
        default:
            break
        }
    }

    private func sendJsEvent(for event: DelegateEvent) async {
        guard let jsEvent = event.toJsEvent() else { return }
        await sendEvent(jsEvent)
    }

    // MARK: - JsMessageProcessor
    public let handlerName: String = "bluetooth"
    private var context: JsContext?

    public func didAttach(to context: JsContext) async {
        self.context = context
    }

    public func didDetach(from context: JsContext) async {
        await effector.cancelAllEvents(with: BluetoothError.cancelled)
        self.context = nil
    }

    private func sendEvent(_ event: JsEventEncodable) async {
        await context?.sendEvent(event.toJsEvent())
    }

    public func process(request: JsMessageRequest) async -> JsMessageResponse {
        do {
            let message = try extractMessage(from: request).get()
            let response = try await processAction(message: message)
            return response.toJsMessage()
        } catch {
            return .error(error.toDomError())
        }
    }

    func processAction(message: Message) async throws -> JsMessageEncodable {
        let action = try message.buildAction(selector: deviceSelector, client: client.request).get()
        return try await action.execute(state: state, effector: effector)
    }
}
