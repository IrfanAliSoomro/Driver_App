# WebSocket client guide

## Your working port

Database Mart maps **public 10039 → inner 80**. Use **10039** for both REST and WebSocket (no separate 8081 mapping needed).

## REST API

```
http://69.197.174.68:10039/api/...
```

Example: `http://69.197.174.68:10039/api/auth/google`

## WebSocket config

```
GET http://69.197.174.68:10039/api/ws
```

## WebSocket connection

```
ws://69.197.174.68:10039/ws?token=<JWT>
```

## Flow

1. Connect with JWT in query string, or send after connect:

```json
{"type":"auth","token":"<JWT>"}
```

2. Subscribe:

```json
{"type":"subscribe","channel":"chat","group":"ohare"}
{"type":"subscribe","channel":"presence"}
{"type":"subscribe","channel":"notifications"}
{"type":"subscribe","channel":"price_alerts"}
```

3. Events: `chat.message.new`, `chat.message.deleted`, `presence.counts`, `notification`, `price_alert.new`, `price_alert.updated`, `price_alert.deleted`

4. Keepalive: `{"type":"ping"}` → `{"type":"pong"}`

## Note on port 8081

`http://69.197.174.68:8081/health` only works if you add a **separate** port mapping (8081 → 8081). You do **not** need it when using `ws://...:10039/ws`.
