import Bluetooth
import BluetoothAction
import BluetoothClient
import BluetoothMessage
import DevicePicker
import Foundation
import JsMessage

/**
 Main engine - owns state, integrates web API with native API
 */
public actor BluetoothEngine: JsMessageProcessor {
    private var isEnabled: Bool = false
    private let state: BluetoothState
    private let client: BluetoothClient
    private let deviceSelector: InteractiveDeviceSelector

    public init(
        state: BluetoothState,
        client: BluetoothClient,
        deviceSelector: InteractiveDeviceSelector
    ) {
        self.state = state
        self.client = client
        self.deviceSelector = deviceSelector
        Task {
            for await event in self.client.events {
                await handleDelegateEvent(event)
            }
        }
    }

    // MARK: - Bluetooth Events

    private func handleDelegateEvent(_ event: BluetoothEvent) async {
        await updateState(for: event)
        await sendJsEvent(for: event)
    }

    private func updateState(for event: BluetoothEvent) async {
        switch event {
        case let event as SystemStateEvent:
            await state.setSystemState(event.systemState)
        default:
            break
        }
    }

    private func sendJsEvent(for event: BluetoothEvent) async {
        guard let jsEvent = event.toJsEvent() else { return }
        await sendEvent(jsEvent)
    }

    // MARK: - JsMessageProcessor
    public let handlerName: String = "bluetooth"
    private var context: JsContext?

    public func didAttach(to context: JsContext) async {
        // TODO: support multiple active web page contexts
        self.context = context
    }

    public func didDetach(from context: JsContext) async {
        // TODO: keep track of how many active contexts are using BLE and when it becomes zero:
        // await client.disable()
        // self.isEnabled = false
        // TODO: support multiple active web page contexts because this cancels all web pages
        await client.cancelPendingRequests()
        self.context = nil
    }

    private func sendEvent(_ event: JsEventEncodable) async {
        await context?.sendEvent(event.toJsEvent())
    }

    public func process(request: JsMessageRequest) async -> JsMessageResponse {
        if !isEnabled {
            await client.enable()
            isEnabled = true
        }
        do {
            let message = try request.extractMessage().get()
            let response = try await processAction(message: message)
            return response.toJsMessage()
        } catch {
            return .error(error.toDomError())
        }
    }

    func processAction(message: Message) async throws -> JsMessageEncodable {
        let action = try message.buildAction(client: client, selector: deviceSelector).get()
        if action.requiresReadyState {
            try await bluetoothReadyState()
        }
        return try await action.execute(state: state, client: client)
    }

    // MARK: - Private Helpers

    /// Blocks until we are in powered on state
    /// Throws an error if the state is not powered on
    private func bluetoothReadyState() async throws {
        try await checkSystemState { state in
            switch state {
            case .poweredOn:
                true
            case .unsupported, .unauthorized, .poweredOff:
                throw BluetoothError.unavailable
            case .unknown, .resetting:
                // Keep waiting - the system emits unknown until it has finished starting up
                false
            }
        }
    }

    private func checkSystemState(predicate: @Sendable (SystemState) throws -> Bool) async throws {
        let currentState = await self.state.systemState
        guard try predicate(currentState) == false else { return }
        _ = try await client.awaitSystemState(predicate: predicate)
    }
}
