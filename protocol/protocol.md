# MyRemote WebSocket protocol

The agent listens on `ws://0.0.0.0:8765/ws`. Messages are UTF-8 JSON objects.
The upgrade request must contain `Authorization: Bearer <connection key>`.
The agent displays a random key at startup, or uses `MYREMOTE_KEY` when set.
Missing/wrong credentials return HTTP 401 before WebSocket upgrade.

Client to agent:

```json
{"type":"ping"}
{"type":"test_message","text":"Hello Windows"}
```

Agent responses:

```json
{"type":"hello","name":"PC-NAME","version":"0.1.0"}
{"type":"pong"}
{"type":"message_received","text":"Hello Windows"}
{"type":"error","message":"..."}
```

Future commands should keep `type` as the discriminator and add only type-specific fields.

Only text messages are accepted, with a maximum size of 16 KiB (including fragments).
Invalid JSON, missing fields, invalid field types, and unknown commands return an
`error` while keeping the connection usable. Binary and oversized messages close
the connection with policy violation (1008). The `hello` name is the PC hostname.
`GET /health` returns the agent name and version without authentication.
TLS is not yet implemented; use only on a trusted private LAN.

Supported authenticated control commands:

```json
{"type":"mouse_move","dx":12,"dy":-5}
{"type":"mouse_click","button":"left"}
{"type":"mouse_scroll","delta":120}
{"type":"keyboard","text":"안녕하세요"}
{"type":"key","key":"enter"}
{"type":"volume","action":"up"}
{"type":"media","action":"play_pause"}
```

Mouse movement integers: -1000..1000. Scroll: -1200..1200 (120 is one notch).
Buttons: left/right. Text: at most 2000 UTF-16 units.
Keys: enter, escape, tab, backspace, left, up, right, down.
Volume actions: up/down/mute. Media: play_pause/previous/next/stop.
Success: `{"type":"command_completed","command":"mouse_move"}`.
Validation or Windows input failure returns `error`.
