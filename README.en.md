# CloudPlatter

[中文](README.md)

[![CI](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml/badge.svg)](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml)

CloudPlatter is an open-source desktop turntable that gives the music already playing on your Mac a lightweight, immersive visual presence.

The first release targets the NetEase Cloud Music macOS client. It reads local Now Playing information and presents the current track as a desktop vinyl scene. CloudPlatter does not replace the player, require a separate music-account login, or upload listening history.

## Status

The project is currently in research and prototyping. The first milestone is validating reliable, read-only Now Playing metadata from the NetEase Cloud Music macOS client.

## Planned MVP

- Detect play, pause, and track changes from NetEase Cloud Music
- Show the current title, artist, album, and artwork
- Render a lightweight animated turntable on the desktop
- Provide menu bar controls for visibility, launch at login, and reduced motion
- Work locally without another NetEase Cloud Music login

## Technical direction

- Swift and AppKit for the macOS application and desktop window
- SwiftUI and Core Animation for settings and the turntable scene
- A small, isolated MediaRemote adapter for read-only Now Playing data
- GitHub Releases for downloadable builds

CloudPlatter relies on undocumented macOS media interfaces for cross-application Now Playing data. Those interfaces may change between macOS releases. Downloaded builds may also require manual approval in macOS Privacy & Security settings unless they are signed and notarized.

## Development and contributing

Chinese is the project's default documentation language, with English maintained as a synchronized translation. Code identifiers are written in English, while code comments are written in Chinese. See [CONTRIBUTING.md](CONTRIBUTING.md) for the complete conventions.

```bash
make check
make package VERSION=0.1.0-dev
```

- [Project roadmap (Chinese)](docs/ROADMAP.md)
- [Domain context (Chinese)](CONTEXT.md)
- [Architecture decisions (Chinese)](docs/adr/README.md)

## Project independence

CloudPlatter is an independent, unofficial open-source project. It is not affiliated with or endorsed by NetEase Cloud Music, Apple, or Vinyl for Mac. Product names and artwork remain the property of their respective owners.

## License

[MIT](LICENSE)
