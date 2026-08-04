import Foundation

public struct NowPlayingState: Equatable, Sendable {
  public enum PlaybackStatus: Equatable, Sendable {
    case idle
    case playing
    case paused
    case unavailable
  }

  public let sourceBundleIdentifier: String?
  public let title: String?
  public let artist: String?
  public let album: String?
  public let artwork: Data?
  public let duration: TimeInterval?
  public let elapsed: TimeInterval?
  public let playbackRate: Double
  public let status: PlaybackStatus

  public init(
    sourceBundleIdentifier: String? = nil,
    title: String? = nil,
    artist: String? = nil,
    album: String? = nil,
    artwork: Data? = nil,
    duration: TimeInterval? = nil,
    elapsed: TimeInterval? = nil,
    playbackRate: Double = 0,
    status: PlaybackStatus
  ) {
    self.sourceBundleIdentifier = sourceBundleIdentifier
    self.title = title
    self.artist = artist
    self.album = album
    self.artwork = artwork
    self.duration = duration
    self.elapsed = elapsed
    self.playbackRate = playbackRate
    self.status = status
  }

  public static let idle = NowPlayingState(status: .idle)
}
