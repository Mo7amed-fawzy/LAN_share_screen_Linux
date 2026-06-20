# LAN Share Screen (Linux)

A real-time screen sharing application for local networks, built with Flutter and [LiveKit](https://livekit.io/). Designed for small teams who need low-latency screen sharing without an internet dependency.

## Features

- **LAN Screen Sharing** — Share your screen with other participants on the same local network.
- **LiveKit-Powered** — Uses LiveKit for WebRTC-based media streaming with automatic room management.
- **JWT Token Generation** — Generates LiveKit tokens locally using HMAC-SHA256 — no external token server required.
- **Self-Hosted Signaling** — Just run `livekit-server --dev` on any machine in your LAN.
- **Real-Time Video** — Low-latency H.264 encoding with simulcast support.
- **Cross-Viewer Layout** — Gallery mode (grid of participants) and Focus mode (single participant).
- **Linux Native** — Built as a native Linux desktop application using Flutter's Linux desktop support.
- **Clean Architecture** — Feature-first structure with Riverpod state management.

## Architecture

```
lib/
├── core/                       # Shared infrastructure
│   ├── constants/              # App & environment config
│   ├── di/                     # Dependency injection
│   ├── error/                  # Error handling & failures
│   ├── network/               # JWT token generation
│   ├── theme/                  # Colors, dimensions, app theme
│   └── utils/                  # Extensions & logging
├── features/                   # Feature modules
│   ├── layout/                 # App shell, screens, layout state
│   ├── participant/            # Participant tracking & rendering
│   ├── room/                   # Room connection & state
│   └── screen_capture/         # Screen capture & publishing
└── shared/                     # Reusable widgets
    └── widgets/                # VideoRenderer, ErrorView, etc.
```

Each feature follows **clean architecture** internally:

```
feature/
├── data/          — Repository implementations
├── domain/        — Entities, services, business logic
└── presentation/  — Providers (Riverpod), widgets
```

## Prerequisites

- Flutter SDK ≥ 3.27.0 with Linux desktop support enabled
- [LiveKit Server](https://github.com/livekit/livekit) (for signaling and media routing)
- Linux desktop with:
  - **PipeWire** + **xdg-desktop-portal** (for screen capture)
  - **GTK+ 3.0** development libraries
  - X11 display server

## Quick Start

### 1. Install System Dependencies

```bash
sudo apt install pipewire pipewire-pulse xdg-desktop-portal xdg-desktop-portal-wlr wireplumber
```

Ensure services are running:

```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

### 2. Install LiveKit Server

Download the latest release from [livekit/livekit](https://github.com/livekit/livekit/releases) or use a package manager:

```bash
# Via Go (if you have Go installed)
go install github.com/livekit/livekit@latest

# Or download the binary manually
curl -sL https://github.com/livekit/livekit/releases/download/v1.13.1/livekit_1.13.1_linux_amd64.tar.gz | tar xz
sudo mv livekit-server /usr/local/bin/
```

### 3. Run the Application

**Terminal 1 — LiveKit Server:**

```bash
livekit-server --dev --bind 0.0.0.0
```

**Terminal 2 — App Instance A:**

```bash
cd screen_share
flutter run -d linux
```

**Terminal 3 — App Instance B:**

```bash
flutter run -d linux
```

Both instances auto-join the `screen_share` room. Click the **Share Screen** button to start sharing.

### Using bootstrap.sh

If cloning into a fresh Flutter project:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

## Configuration

Environment variables can be passed via `--dart-define`:

| Variable | Default | Description |
|----------|---------|-------------|
| `LIVEKIT_URL` | `ws://192.168.1.9:7880` | LiveKit server WebSocket URL |
| `LIVEKIT_API_KEY` | `devkey` | LiveKit API key |
| `LIVEKIT_API_SECRET` | `secret` | LiveKit API secret |

Example:

```bash
flutter run -d linux --dart-define=LIVEKIT_URL=ws://192.168.1.100:7880
```

## How It Works

1. **Room Connection** — Each app instance generates a JWT token locally and connects to the LiveKit server via WebSocket.
2. **Participant Discovery** — LiveKit notifies all participants when someone joins or leaves. The app tracks this via a ChangeNotifier on the Room object.
3. **Screen Sharing** — The sharer clicks "Share Screen", selects a display via the PipeWire portal, creates a `LocalVideoTrack`, and publishes it to the room.
4. **Viewing** — Other participants auto-subscribe to published tracks. Video frames are decoded and rendered via `VideoTrackRenderer`.

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `livekit_client` | WebRTC room management, track publishing/subscription |
| `flutter_webrtc` | Screen capture (`getDisplayMedia`) |
| `flutter_riverpod` | State management (providers, notifiers) |
| `crypto` | HMAC-SHA256 for JWT token generation |

## Development

### Run Analyzer

```bash
flutter analyze
```

### Project Structure

Each feature is independent and can be tested in isolation. Shared widgets live under `lib/shared/`. The `core/` directory contains cross-cutting concerns used by all features.

## License

MIT
