# MyRemote WebSocket protocol

The agent listens on `ws://0.0.0.0:8765/ws`. Messages are UTF-8 JSON objects.

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
`GET /health` returns the agent name and version. No authentication or TLS is
implemented in Phase 1; use on a trusted LAN only. PC control commands are not
implemented or executed.
