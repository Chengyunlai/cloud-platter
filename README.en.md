# CloudPlatter

[中文](README.md)

[![CI](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml/badge.svg)](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml)

When you play music in NetEase Cloud Music on your Mac, CloudPlatter turns the desktop into a full-screen walnut turntable scene. The current artwork, vinyl, and tonearm become part of a living desktop background.

You can keep using the player you already know. CloudPlatter reads local Now Playing information and provides Previous, Play/Pause, and Next desktop controls; it does not replace the player, require another music-account login, or upload your listening history.

## Status

The project is currently in research and prototyping. Real-time title, artist, album, artwork, playback state, and track-change updates have been verified on macOS 26.3 with NetEase Cloud Music 3.1.9. Additional content types, app restarts, and system versions still require compatibility validation.

## Planned MVP

- Detect play, pause, and track changes from NetEase Cloud Music
- Show the current title, artist, album, and artwork
- Render a click-through, full-screen animated turntable desktop on every display
- Control the current NetEase Cloud Music session with Previous, Play/Pause, and Next desktop buttons
- Provide menu bar controls for visibility, launch at login, and reduced motion
- Work locally without another NetEase Cloud Music login

## Technical direction

- Swift and AppKit for the macOS application and per-display full-screen desktop windows
- SwiftUI and Core Animation for settings and the turntable scene
- A replaceable observation source that lets the system `/usr/bin/perl` process load an isolated MediaRemote helper; an empty, unavailable, or timed-out silent event stream first triggers a one-shot MediaRemote snapshot, then an on-demand NetEase-targeted `/usr/bin/osascript` query if needed
- Source filtering at the application boundary before private fields are converted into the project's own playback state
- A fresh source check before every playback command so another media player is never controlled by mistake
- GitHub Releases for downloadable builds

The default observation path and its on-demand fallback do not require Accessibility or Screen & System Audio Recording permission, and they do not upload listening history. They rely on undocumented MediaRemote behavior and the `/usr/bin/perl` and `/usr/bin/osascript` currently bundled with macOS, so a future system update may break them and they are not suitable for Mac App Store distribution; the app performs capability checks and degrades safely when unavailable. Downloaded builds may also require manual approval in macOS Privacy & Security settings unless they are signed and notarized. See [ADR-0004](docs/adr/0004-isolated-mediaremote-adapter.md) for the technical boundary.

## Development and contributing

Chinese is the project's default documentation language, with English maintained as a synchronized translation. Code identifiers are written in English, while code comments are written in Chinese. See [CONTRIBUTING.md](CONTRIBUTING.md) for the complete conventions.

```bash
git submodule update --init --recursive
make check
make adapter
make package VERSION=0.1.0-dev
```

- [Project roadmap (Chinese)](docs/ROADMAP.md)
- [Domain context (Chinese)](CONTEXT.md)
- [Architecture decisions (Chinese)](docs/adr/README.md)
- [Playback-source research (Chinese)](docs/research/now-playing-data-source-2026-08.md)
- [macOS 26.3 / NetEase Cloud Music 3.1.9 compatibility matrix (Chinese)](docs/compatibility/macos-26-netease-3.1.9.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Security policy (Chinese)](SECURITY.md)

## Project independence

CloudPlatter is an independent, unofficial open-source project. It is not affiliated with or endorsed by NetEase Cloud Music, Apple, or Vinyl for Mac. Product names and artwork remain the property of their respective owners.

## License

[MIT](LICENSE)
