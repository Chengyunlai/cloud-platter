# CloudPlatter

An open-source desktop turntable for the music already playing on your Mac.

CloudPlatter is planned as a lightweight macOS companion for NetEase Cloud Music. It will visualize the current track as a desktop vinyl scene without replacing the player, signing into a music account, or uploading listening history.

## Status

Research and prototyping. The first milestone is validating reliable read-only Now Playing metadata from the NetEase Cloud Music macOS client.

## Planned MVP

- Detect play, pause, and track changes from NetEase Cloud Music
- Show the current title, artist, album, and artwork
- Render a lightweight animated turntable on the desktop
- Provide menu bar controls for visibility, launch at login, and reduced motion
- Work locally without a NetEase account login

## Technical direction

- Swift and AppKit for the macOS application and desktop window
- SwiftUI and Core Animation for settings and the turntable scene
- A small, isolated MediaRemote adapter for read-only Now Playing data
- GitHub Releases for downloadable builds

CloudPlatter relies on undocumented macOS media interfaces for cross-application Now Playing data. Those interfaces may change between macOS releases. Downloaded builds may also require manual approval in macOS Privacy & Security settings unless they are signed and notarized.

## Project independence

CloudPlatter is an independent, unofficial open-source project. It is not affiliated with or endorsed by NetEase Cloud Music, Apple, or Vinyl for Mac. Product names and artwork remain the property of their respective owners.

## License

[MIT](LICENSE)
