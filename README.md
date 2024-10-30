# topaz
Bluetooth Enabled Web Browser for iOS

## Data flow

JavaScript/Bluetooth ->
JavaScript/WebKit.bluetoothRequest ->
WebView/ScriptHandler.userContentController(message: WKScriptMessage) -> // `message` is converted to `[String: JsType]` where `JsType` is Native-friendly
BluetoothClient/BluetoothEngine.process(request: JsMessageRequest) -> // `JsMessageRequest.body` is of type: `[String: JsType]`; `request` is converted to `BluetoothClient/Messages/Message`
BluetoothClient/BluetoothEngine.process(request: Message) -> // `request` -> `message`
BluetoothClient/BluetoothEngine.<function>(message: Message) returns `JsMessageEncodable` // e.g. `connect(message: Message)` -> `ConnectRequest.decode(message)`
`JsMessageEncodable` is converted to `JsMessageResponse` via `JsMessageEncodable.toJsMessage()`
`WebView/ScriptHandler.userContentController` returns as `(Any?, String?)`


WebBluetoothRequest.decode ->
BluetoothClient/JsDecodable


| Type     | Boundary            | Protocol             |
|----------|---------------------|----------------------|
| Request  | Swift -> JavaScript | `JsMessageDecodable` |
| Response | JavaScript -> Swift | `JsMessageEncodable` |
| Event    | JavaScript -> Swift | `JsEventEncodable`   |
