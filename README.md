# Bloom

Hand-therapy exercise app for iOS, plus the small relay server that powers Therapist Mode.

## Layout

- `Bloom/`, `Bloom.xcodeproj` — the iOS app (SwiftUI, Xcode 26+, iOS 26+)
- `Server/` — Hummingbird WebSocket relay (Swift package), deployed to Fly.io

## iOS app

Open `Bloom.xcodeproj` in Xcode and run the `Bloom` scheme.

The app works fully offline. Only Therapist Mode talks to the server. The server URL
defaults to `wss://opbloom.fly.dev` and can be changed in the app under
Profile → Server Settings, or on the Therapist Mode screen.

## Server

The server keeps no state. Phones join a room by 6-digit code and every message
sent to the room is re-broadcast to everyone in it.

Run locally:

```bash
cd Server
swift run PlayPen --hostname 0.0.0.0 --port 8080
```

Point the app at `ws://<your-mac-ip>:8080` to test against it.

Run tests:

```bash
cd Server
swift test
```

Deploy (uses `Server/fly.toml`, which targets the `opbloom` Fly app):

```bash
cd Server
fly deploy
```
