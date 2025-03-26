import Bluetooth
import BluetoothAction
import BluetoothClient
import BluetoothMessage
import DevicePicker
import Foundation
import JsMessage
import OSLog

private let messageLog = Logger(subsystem: "BluetoothEngine", category: "Message")

/**
 Main engine - owns state, integrates web API with native API
 */
public actor BluetoothEngine: JsMessageProcessor {

    enum RunState { case ready, running(JsContext), shutdown }

    private var runState: RunState = .ready
    private var isEnabled: Bool = false
    private let state: BluetoothState
    private let client: BluetoothClient
    private let deviceSelector: InteractiveDeviceSelector
    private var jsEventForwarder: JsEventForwarder
    private var task: Task<Void, Never>?

    public init(
        state: BluetoothState,
        client: BluetoothClient,
        deviceSelector: InteractiveDeviceSelector,
        enableDebugLogging: Bool = false
    ) {
        self.state = state
        self.client = client
        self.deviceSelector = deviceSelector
        self.enableDebugLogging = enableDebugLogging
        self.jsEventForwarder = JsEventForwarder { _ in }
    }

    // MARK: - Bluetooth Events

    private func handleDelegateEvent(_ event: BluetoothEvent) async {
        // Note: order of processing is super important here
        await updateState(for: event)
        await sendJsEvent(for: event)
        await client.resolvePendingRequests(for: event)
        await handleUnexpectedDisconnect(for: event)
    }

    // On unexpected disconnect reject all pending operations for the peripheral
    private func handleUnexpectedDisconnect(for event: BluetoothEvent) async {
        guard case let DisconnectionEvent.unexpected(peripheral, cause) = event else {
            return
        }
        let disconnectionErrorEvent = ErrorEvent(
            error: cause,
            lookup: .wildcard(peripheralId: peripheral.id)
        )
        await client.resolvePendingRequests(for: disconnectionErrorEvent)
    }

    private func updateState(for event: BluetoothEvent) async {
        switch event {
        case let event as SystemStateEvent:
            await BluetoothSystemState.shared.updateSystemState(event.systemState)
            await state.setSystemState(event.systemState)
        case let event as PeripheralEvent where event.name == .canSendWriteWithoutResponse:
            await state.setCanSendWriteWithoutResponse(event.peripheral.id, value: true)
        default:
            break
        }
    }

    private func sendJsEvent(for event: BluetoothEvent) async {
        guard let jsEvent = event.toJsEvent() else { return }
        await sendEvent(jsEvent)
    }

    // MARK: - JsMessageProcessor
    public static let handlerName: String = "bluetooth"
    public let enableDebugLogging: Bool

    public func didAttach(to context: JsContext) async {
        if case .ready = self.runState {
            self.runState = .running(context)
            self.task = Task {
                for await event in self.client.events {
                    await handleDelegateEvent(event)
                }
            }
            self.jsEventForwarder = JsEventForwarder { [weak self] event in
                await self?.sendEvent(event)
            }
        }
    }

    public func didDetach(from context: JsContext) async {
        // Note: carefully orchestrate the tear-down to avoid request/response races here
        // Firstly, modify runState immediately so all future requests and events are dropped
        self.runState = .shutdown

        // Shut down the delegate event handler
        self.task?.cancel()
        self.task = nil
        self.jsEventForwarder = JsEventForwarder { _ in }

        // Shut down any active scans
        await state.removeAllScanTasks().forEach { $0.cancel() }

        // Tell the system to disconnect all known peripherals and then shutdown
        let peripherals = await state.removeAllPeripherals()
        await client.prepareForShutdown(peripherals: peripherals)
        await client.disable()
    }

    private func sendEvent(_ event: JsEvent) async {
        guard case let .running(context) = self.runState else { return }
        if enableDebugLogging {
            messageLog.debug("Event \(event.eventName, privacy: .public): \(event.asDebugString(), privacy: .public)")
        }
        let result = await context.sendEvent(event)
        if case let .failure(error) = result {
            messageLog.error("Event send failed \(event.eventName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    public func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        guard case .running = self.runState else {
            return .error(BluetoothError.unavailable.toDomError())
        }
        if !self.isEnabled {
            await client.enable()
            self.isEnabled = true
        }
        var actionForFailureLogging: Message.Action?
        do {
            let message = try request.extractMessage().get()
            actionForFailureLogging = message.action
            logRequest(message: message)
            let response = try await processAction(message: message).toJsMessage()
            logResponse(action: message.action, response: response)
            return response
        } catch {
            let errorResponse = JsMessageResponse.error(error.toDomError())
            logResponse(action: actionForFailureLogging, response: errorResponse)
            return errorResponse
        }
    }

    func processAction(message: Message) async throws -> JsMessageEncodable {
        let action = try message.buildAction(client: client, selector: deviceSelector, jsEventForwarder: jsEventForwarder).get()
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
            case .poweredOff:
                throw BluetoothError.turnedOff
            case .unauthorized:
                throw BluetoothError.unauthorized
            case .unsupported:
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

    private func logRequest(message: Message) {
        guard enableDebugLogging else { return }
        messageLog.debug("Request \(message.action.rawValue, privacy: .public): \(JsType.dictionaryAsString(message.rawRequestData), privacy: .public)")
    }

    private func logResponse(action: Message.Action?, response: JsMessageResponse) {
        guard enableDebugLogging else { return }
        let actionString = action?.rawValue ?? "?"
        switch response {
        case let .body(body):
            messageLog.debug("Response \(actionString, privacy: .public): \(body.asDebugString(), privacy: .public)")
        case let .error(error):
            messageLog.error("Response \(actionString, privacy: .public): \(error.jsRepresentation, privacy: .public)")
        }
    }
}
