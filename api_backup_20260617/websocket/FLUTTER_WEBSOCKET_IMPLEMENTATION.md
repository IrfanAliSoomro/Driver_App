# Flutter WebSocket Implementation Guide (Driver Grid API)

Use this document in Cursor when implementing WebSocket in the Flutter app.
Copy sections into your Flutter project or reference with `@FLUTTER_WEBSOCKET_IMPLEMENTATION.md`.

---

## 1. Server endpoints (production)

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://69.197.174.68:10039/api';
  static const String wsUrl = 'ws://69.197.174.68:10039/ws';

  // Optional: fetch at runtime instead of hardcoding
  // GET $baseUrl/ws → data.url, data.enabled, data.protocol
}
```

| Purpose | URL |
|---------|-----|
| REST API | `http://69.197.174.68:10039/api` |
| WS config | `GET /api/ws` |
| WebSocket | `ws://69.197.174.68:10039/ws?token=<JWT>` |
| Google login | `POST /api/auth/google` → returns `data.token` |

---

## 2. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  web_socket_channel: ^3.0.1
  # you likely already have:
  # http or dio, shared_preferences or flutter_secure_storage
```

```bash
flutter pub get
```

---

## 3. Auth flow (JWT required for WebSocket)

WebSocket uses the **same JWT** as REST API.

### Login (existing flow)

```http
POST /api/auth/google
Content-Type: application/json

{
  "id_token": "<google-id-token>",
  "user_id": "103343709493359555007",
  "email": "user@example.com",
  "display_name": "John Doe",
  "fcm_token": "<optional>"
}
```

### Response

```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": { "user_id": "...", "email": "..." },
    "blocked": false
  }
}
```

**Store `data.token`** in `SharedPreferences` or `FlutterSecureStorage`.
Token expires in **24 hours** — refresh via `POST /api/auth/refresh` with `Authorization: Bearer <token>`.

---

## 4. WebSocket protocol

### 4.1 Connect

```
ws://69.197.174.68:10039/ws?token=<JWT>
```

On connect, server sends:

```json
{"type":"connected","message":"Send {\"type\":\"auth\",\"token\":\"<JWT>\"} then subscribe to channels"}
```

If token in URL is valid:

```json
{"type":"authenticated","user_id":"103343709493359555007"}
```

**Alternative:** connect without `?token=` then send:

```json
{"type":"auth","token":"<JWT>"}
```

### 4.2 Subscribe (after authenticated)

```json
{"type":"subscribe","channel":"chat","group":"ohare"}
{"type":"subscribe","channel":"chat","group":"midway"}
{"type":"subscribe","channel":"presence"}
{"type":"subscribe","channel":"notifications"}
{"type":"subscribe","channel":"price_alerts"}
```

Server confirms:

```json
{"type":"subscribed","channel":"chat","group":"ohare"}
{"type":"subscribed","channel":"presence"}
```

Valid chat groups: any slug like `ohare`, `midway`, `ord-limo-lot` (lowercase, hyphens allowed).

### 4.3 Unsubscribe

```json
{"type":"unsubscribe","channel":"chat","group":"ohare"}
{"type":"unsubscribe","channel":"presence"}
```

### 4.4 Keepalive (every 25–30 seconds)

```json
{"type":"ping"}
```

Response:

```json
{"type":"pong"}
```

### 4.5 Server → client events

All events use this envelope:

```json
{
  "type": "<event_name>",
  "payload": { ... },
  "ts": 1717776000000
}
```

| `type` | `payload` shape | When |
|--------|-----------------|------|
| `chat.message.new` | `{ "group": "ohare", "message": { ... } }` | New chat message |
| `chat.message.deleted` | `{ "group": "ohare", "message_id": 123 }` | Message deleted |
| `presence.counts` | `{ "counts": { "MidwayLot": 2, "OhareAlphaLot": 0 } }` | Lot counts change |
| `notification` | `{ "user_id": "...", "title": "...", "body": "...", "data": {}, "type": "general" }` | Push-style alert |
| `price_alert.new` | `{ "price_alert": { "id", "pickup", "dropoff", "price", ... } }` | New price alert created |
| `price_alert.updated` | `{ "price_alert": { ... } }` | Alert edited or reaction changed |
| `price_alert.deleted` | `{ "alert_id": 12 }` | Alert deleted |
| `error` | N/A — `{ "type":"error", "message":"..." }` | Client error |

### 4.6 Chat message object (`payload.message`)

```json
{
  "id": 42,
  "group_name": "ohare",
  "group": "ohare",
  "user_id": "103343709493359555007",
  "text": "Hello drivers",
  "reply_to_message_id": null,
  "reply_to": null,
  "display_name": "John Doe",
  "photo_url": "https://...",
  "created_at": "2026-06-07T12:00:00.000Z"
}
```

**Reply message** — `reply_to` is populated when `reply_to_message_id` is set:

```json
{
  "id": 43,
  "text": "Yes I'm here",
  "reply_to_message_id": 42,
  "reply_to": {
    "id": 42,
    "user_id": "...",
    "display_name": "John Doe",
    "text": "Anyone at the lot?",
    "created_at": "2026-06-07T12:00:00.000Z"
  }
}
```

**Send reply (REST):**

```http
POST /api/chat/ohare
{ "text": "Yes I'm here", "reply_to_message_id": 42 }
```

---

## 5. Flutter models

```dart
// lib/models/ws_event.dart
class WsEvent {
  final String type;
  final Map<String, dynamic>? payload;
  final int? ts;

  WsEvent({required this.type, this.payload, this.ts});

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>?,
        ts: json['ts'] as int?,
      );
}

// lib/models/chat_message.dart
class ChatMessage {
  final int id;
  final String group;
  final String userId;
  final String text;
  final String? displayName;
  final String? photoUrl;
  final String? createdAt;

  ChatMessage({
    required this.id,
    required this.group,
    required this.userId,
    required this.text,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  factory ChatMessage.fromWsPayload(Map<String, dynamic> payload) {
    final m = payload['message'] as Map<String, dynamic>;
    return ChatMessage(
      id: m['id'] as int,
      group: (m['group'] ?? m['group_name'] ?? payload['group']) as String,
      userId: m['user_id'] as String,
      text: m['text'] as String,
      displayName: m['display_name'] as String?,
      photoUrl: m['photo_url'] as String?,
      createdAt: m['created_at'] as String?,
    );
  }
}
```

---

## 6. WebSocket service (core implementation)

```dart
// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

typedef WsEventCallback = void Function(Map<String, dynamic> event);

class WebSocketService {
  WebSocketService({
    required this.wsBaseUrl, // ws://69.197.174.68:10039/ws
    required this.getToken,  // () async => stored JWT
  });

  final String wsBaseUrl;
  final Future<String?> Function() getToken;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  bool _authenticated = false;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect() async {
    await disconnect();

    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No JWT token — login first');
    }

    final uri = Uri.parse('$wsBaseUrl?token=${Uri.encodeComponent(token)}');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (e) => _eventController.add({'type': 'ws.error', 'message': '$e'}),
      onDone: _onDisconnected,
      cancelOnError: false,
    );

    _startPing();
  }

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = json['type'] as String?;
    if (type == null) return;

    if (type == 'authenticated') {
      _authenticated = true;
      _subscribeDefaults();
    }

    _eventController.add(json);
  }

  void _subscribeDefaults() {
    // Subscribe to all channels your app needs
    subscribePresence();
    subscribeNotifications();
    subscribePriceAlerts();
    // Chat groups subscribed when user opens chat screen
  }

  void subscribeChat(String group) {
    _send({'type': 'subscribe', 'channel': 'chat', 'group': group});
  }

  void unsubscribeChat(String group) {
    _send({'type': 'unsubscribe', 'channel': 'chat', 'group': group});
  }

  void subscribePresence() {
    _send({'type': 'subscribe', 'channel': 'presence'});
  }

  void subscribeNotifications() {
    _send({'type': 'subscribe', 'channel': 'notifications'});
  }

  void subscribePriceAlerts() {
    _send({'type': 'subscribe', 'channel': 'price_alerts'});
  }

  void _send(Map<String, dynamic> msg) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(msg));
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({'type': 'ping'});
    });
  }

  void _onDisconnected() {
    _authenticated = false;
    _eventController.add({'type': 'ws.disconnected'});
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    _subscription = null;
    _authenticated = false;
  }

  /// Call on app resume or token refresh
  Future<void> reconnect() => connect();
}
```

---

## 7. App integration (Provider / Riverpod example)

### 7.1 Initialize after login

```dart
// After POST /api/auth/google succeeds:
await secureStorage.write(key: 'jwt', value: data['token']);
await webSocketService.connect();
```

### 7.2 Listen in UI

```dart
// lib/screens/chat_screen.dart
class ChatScreen extends StatefulWidget {
  final String group; // e.g. 'ohare'
  const ChatScreen({required this.group});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    webSocketService.subscribeChat(widget.group);
    _loadInitialMessages(); // GET /api/chat/{group}
    _wsSub = webSocketService.events.listen(_handleWsEvent);
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type == 'chat.message.new') {
      final payload = event['payload'] as Map<String, dynamic>;
      if (payload['group'] == widget.group) {
        setState(() => _messages.add(ChatMessage.fromWsPayload(payload)));
      }
    }
    if (type == 'chat.message.deleted') {
      final payload = event['payload'] as Map<String, dynamic>;
      final id = payload['message_id'] as int;
      setState(() => _messages.removeWhere((m) => m.id == id));
    }
  }

  @override
  void dispose() {
    webSocketService.unsubscribeChat(widget.group);
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    // REST still sends the message; WS delivers it to other clients
    await api.post('/chat/${widget.group}', body: {'text': text});
  }
}
```

### 7.3 Presence (parking lots)

```dart
void _handlePresence(Map<String, dynamic> event) {
  if (event['type'] != 'presence.counts') return;
  final counts = event['payload']['counts'] as Map<String, dynamic>;
  // e.g. { "MidwayLot": 2, "OhareAlphaLot": 0 }
  setState(() => _lotCounts = counts.map((k, v) => MapEntry(k, v as int)));
}
```

### 7.4 Notifications (including chat alerts)

Chat messages now also push a `notification` event to each recipient (except sender)
who is subscribed to the `notifications` channel. Use this for banners/badges when
the user is **not** on the chat screen.

```dart
void _handleNotification(Map<String, dynamic> event) {
  if (event['type'] != 'notification') return;
  final p = event['payload'] as Map<String, dynamic>;
  final data = p['data'] as Map<String, dynamic>? ?? {};
  final type = p['type'] as String? ?? data['type'] as String?;

  if (type == 'chat_message') {
    final group = data['group'] as String?;
    // Show banner; tap navigates to chat
    showInAppBanner(
      title: p['title'] as String? ?? 'New message',
      body: p['body'] as String? ?? '',
      onTap: group != null ? () => openChat(group) : null,
    );
    return;
  }

  if (type == 'ride_alert' || type == 'price_alert' || data['type'] == 'ride_alert') {
    showInAppBanner(
      title: p['title'] as String? ?? 'New ride alert',
      body: p['body'] as String? ?? '',
      onTap: () => openPriceAlerts(),
    );
    return;
  }

  showInAppBanner(title: p['title'], body: p['body']);
  // FCM still handles background/killed app; WS handles foreground real-time
}
```

### 7.5 Price alerts

Subscribe globally after login. List screen listens for feed updates; `notification` handles banners when user is elsewhere.

```dart
void _handlePriceAlertEvent(Map<String, dynamic> event) {
  final type = event['type'] as String?;
  final payload = event['payload'] as Map<String, dynamic>? ?? {};

  if (type == 'price_alert.new') {
    final alert = payload['price_alert'] as Map<String, dynamic>;
    setState(() => _alerts.insert(0, PriceAlert.fromJson(alert)));
    return;
  }

  if (type == 'price_alert.updated') {
    final alert = payload['price_alert'] as Map<String, dynamic>;
    final id = alert['id'];
    setState(() {
      final i = _alerts.indexWhere((a) => a.id == id);
      if (i >= 0) _alerts[i] = PriceAlert.fromJson(alert);
    });
    return;
  }

  if (type == 'price_alert.deleted') {
    final id = payload['alert_id'];
    setState(() => _alerts.removeWhere((a) => a.id == id));
  }
}

// In notification handler — ride/price alert banner when not on alerts screen:
if (type == 'ride_alert' || type == 'price_alert' || data['type'] == 'ride_alert') {
  showInAppBanner(title: p['title'], body: p['body'], onTap: () => openPriceAlerts());
}
```

---

## 8. REST + WebSocket together (important)

| Action | Use REST | Use WebSocket |
|--------|----------|---------------|
| Send chat message | `POST /api/chat/{group}` | Recipients get `notification`; chat subscribers get `chat.message.new` |
| Delete message | `DELETE /api/chat/{id}` | Receive `chat.message.deleted` |
| Load chat history | `GET /api/chat/{group}` | — |
| Update location / presence | `POST /api/active-users/increment` | Receive `presence.counts` |
| Admin notification | `POST /api/notifications/send` | Receive `notification` |
| Create price alert | `POST /api/price-alerts` | `price_alert.new` + `notification` (type `ride_alert`) + FCM |
| Update / like alert | `PUT` / `POST .../like` | `price_alert.updated` |
| Delete price alert | `DELETE /api/price-alerts/{id}` | `price_alert.deleted` |
| Load price alerts | `GET /api/price-alerts` | — |

**Pattern:** REST writes data → server pushes WS event → all subscribed clients update UI.

---

## 9. Lifecycle & reconnection

```dart
// main.dart or app widget
class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (isLoggedIn) webSocketService.connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      webSocketService.reconnect();
    }
    if (state == AppLifecycleState.paused) {
      // optional: webSocketService.disconnect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    webSocketService.disconnect();
    super.dispose();
  }
}
```

### Token refresh

When `POST /api/auth/refresh` returns new token:
1. Save new token
2. `disconnect()` then `connect()` with new JWT

### Auto-reconnect on disconnect

```dart
wsSub = webSocketService.events.listen((e) {
  if (e['type'] == 'ws.disconnected') {
    Future.delayed(const Duration(seconds: 3), () {
      webSocketService.reconnect();
    });
  }
});
```

---

## 10. Optional: fetch WS URL at runtime

```dart
Future<String> fetchWsUrl() async {
  final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/ws'));
  final json = jsonDecode(res.body);
  return json['data']['url'] as String; // ws://69.197.174.68:10039/ws
}
```

Use returned URL instead of hardcoded `ApiConfig.wsUrl` if you change servers often.

---

## 11. Cursor prompt (paste into Flutter project chat)

```
Implement WebSocket in this Flutter app using @FLUTTER_WEBSOCKET_IMPLEMENTATION.md.

Requirements:
1. Add web_socket_channel dependency
2. Create WebSocketService singleton with connect/disconnect/subscribe
3. Connect after Google login using stored JWT
4. Subscribe to chat group when ChatScreen opens
5. Subscribe to presence + notifications globally after login
6. Update chat list on chat.message.new / chat.message.deleted
7. Update parking lot counts on presence.counts
8. Show in-app notification on notification event
9. Ping every 25s, reconnect on app resume and disconnect
10. Use existing API base URL http://69.197.174.68:10039/api for REST

Do not remove existing REST calls — WebSocket is for real-time receive only.
```

---

## 12. Testing checklist

- [ ] Login → token saved → WS connects → `authenticated` received
- [ ] Open ohare chat → subscribe → send message from another device → `chat.message.new` appears
- [ ] Increment active user → `presence.counts` updates on other devices
- [ ] Admin send notification → `notification` event received
- [ ] Kill app 30s → reopen → reconnect works
- [ ] Expired token → WS error → refresh token → reconnect

---

## 13. Common errors

| Symptom | Fix |
|---------|-----|
| `Authenticate first` | Send JWT in URL or `auth` message before subscribe |
| `group required for chat` | Include `"group":"ohare"` in subscribe |
| Connection timeout | Use port **10039**, not 8081 |
| No events after send | Must subscribe to channel; REST send triggers WS for **other** clients |
| Token expired | Call `/api/auth/refresh` and reconnect |
