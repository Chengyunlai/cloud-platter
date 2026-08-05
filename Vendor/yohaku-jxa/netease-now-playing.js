// Extracted from YohakuCompanion's JXAMediaInfoProvider.\n// Copyright (c) 2025 Innei. Licensed under the MIT License.\n\nObjC.import("Foundation")
ObjC.bindFunction("dispatch_queue_create", ["id", ["string", "void*"]])
ObjC.bindFunction(
  "objc_msgSend",
  ["void", ["id", "selector", "id", "id"]]
)

function isNil(value) {
  if (value === null || value === undefined) return true
  try {
    return Boolean(value.isNil())
  } catch (_) {
    return false
  }
}

function unwrap(value) {
  if (isNil(value)) return null
  try {
    return ObjC.unwrap(value)
  } catch (_) {
    return null
  }
}

function infoValue(info, key) {
  if (isNil(info)) return null
  return unwrap(info.objectForKey(key))
}

function numericValue(value) {
  if (value === null || value === undefined) return null
  const number = Number(value)
  return isFinite(number) && number >= 0 ? number : null
}

function dateSeconds(value) {
  if (isNil(value)) return null
  try {
    const seconds = Number(value.timeIntervalSince1970)
    return isFinite(seconds) && seconds >= 0 ? seconds : null
  } catch (_) {
    return null
  }
}

function infoDateSeconds(info, key) {
  if (isNil(info)) return null
  return dateSeconds(info.objectForKey(key))
}

function encodedData(value) {
  if (isNil(value)) return null
  try {
    return unwrap(value.base64EncodedStringWithOptions(0))
  } catch (_) {
    return null
  }
}

function artworkData(artwork) {
  if (isNil(artwork)) return null
  try {
    const imageDataSelector = $.NSSelectorFromString("imageData")
    const value = artwork.respondsToSelector(imageDataSelector)
      ? artwork.imageData
      : artwork
    return encodedData(value)
  } catch (_) {
    return null
  }
}

function infoData(info, key) {
  if (isNil(info)) return null
  return encodedData(info.objectForKey(key))
}

function snapshot(
  info,
  bundleIdentifier,
  source,
  playing,
  activityDate,
  artwork
) {
  const playbackRate = numericValue(
    infoValue(info, "kMRMediaRemoteNowPlayingInfoPlaybackRate")
  )
  return {
    activityDate: activityDate,
    album: infoValue(info, "kMRMediaRemoteNowPlayingInfoAlbum"),
    artist: infoValue(info, "kMRMediaRemoteNowPlayingInfoArtist"),
    artworkData: artworkData(artwork) || infoData(
      info,
      "kMRMediaRemoteNowPlayingInfoArtworkData"
    ),
    bundleIdentifier: bundleIdentifier,
    duration: infoValue(info, "kMRMediaRemoteNowPlayingInfoDuration"),
    elapsedTime: infoValue(info, "kMRMediaRemoteNowPlayingInfoElapsedTime"),
    playbackRate: playbackRate,
    playing: playing === null ? playbackRate !== null && playbackRate > 0 : playing,
    source: source,
    title: infoValue(info, "kMRMediaRemoteNowPlayingInfoTitle")
  }
}

// JavaScriptObjC cannot infer object-valued callback signatures that come
// only from a private framework. A Foundation block-taking API
// materializes those native blocks; the holder remains alive until every
// MediaRemote callback has completed. Scalar callbacks must retain their
// explicit ABI and are therefore passed directly.
function materializeNativeBlock(callback) {
  const holder = $.NSPredicate.predicateWithBlock(callback)
  return {
    block: holder.valueForKey("block"),
    holder: holder
  }
}

function run(bundleIdentifiers) {
  const framework = $.NSBundle.bundleWithPath(
    "/System/Library/PrivateFrameworks/MediaRemote.framework"
  )
  if (!framework || !framework.load) {
    throw new Error("Unable to load MediaRemote.framework")
  }

  const MROrigin = $.NSClassFromString("MROrigin")
  const MRPlayer = $.NSClassFromString("MRPlayer")
  const MRPlayerPath = $.NSClassFromString("MRPlayerPath")
  const MRNowPlayingRequest = $.NSClassFromString("MRNowPlayingRequest")
  if (
    isNil(MROrigin) ||
    isNil(MRPlayer) ||
    isNil(MRPlayerPath) ||
    isNil(MRNowPlayingRequest)
  ) {
    throw new Error("Required MediaRemote classes are unavailable")
  }

  const candidates = []
  const states = []
  const keepAlive = []
  const infoSelector = $.NSSelectorFromString(
    "requestNowPlayingInfoWithCompletion:"
  )
  const lastPlayingDateSelector = $.NSSelectorFromString(
    "requestLastPlayingDateWithCompletion:"
  )
  const artworkSelector = $.NSSelectorFromString(
    "requestNowPlayingItemArtworkWithCompletion:"
  )
  // A player's Now Playing info may retain playbackRate=1 after it pauses.
  // Query playback state on the same player path because localIsPlaying can
  // belong to a browser or another concurrent media session.
  const isPlayingSelector = $.NSSelectorFromString(
    "requestIsPlayingOnQueue:completion:"
  )
  const requestQueue = $.dispatch_queue_create(
    "dev.innei.YohakuCompanion.media-remote",
    null
  )

  const playerPath = MRNowPlayingRequest.localNowPlayingPlayerPath
  const client = isNil(playerPath) ? null : playerPath.client
  const item = MRNowPlayingRequest.localNowPlayingItem
  const info = isNil(item) ? null : item.nowPlayingInfo
  const parentBundleIdentifier = !isNil(client)
    ? unwrap(client.parentApplicationBundleIdentifier)
    : null
  const bundleIdentifier = parentBundleIdentifier ||
    (!isNil(client) ? unwrap(client.bundleIdentifier) : null)

  candidates.push(
    snapshot(
      info,
      bundleIdentifier,
      "global",
      Boolean(MRNowPlayingRequest.localIsPlaying),
      infoDateSeconds(info, "kMRMediaRemoteNowPlayingInfoTimestamp"),
      null
    )
  )

  for (const supportedBundleIdentifier of bundleIdentifiers) {
    const state = {
      bundleIdentifier: supportedBundleIdentifier,
      artwork: null,
      artworkCompleted: false,
      dateCompleted: false,
      info: null,
      infoCompleted: false,
      infoError: null,
      isPlaying: null,
      isPlayingCompleted: false,
      lastPlayingDate: null
    }
    states.push(state)

    try {
      const path = MRPlayerPath.alloc.initWithOriginBundleIdentifierPlayer(
        MROrigin.localOrigin,
        supportedBundleIdentifier,
        MRPlayer.defaultPlayer
      )
      const request = MRNowPlayingRequest.alloc.initWithPlayerPath(path)

      if (!request.respondsToSelector(infoSelector)) {
        state.artworkCompleted = true
        state.infoCompleted = true
        state.isPlayingCompleted = true
        state.dateCompleted = true
        continue
      }

      const infoCallback = ObjC.block(
        ["void", ["id", "id"]],
        function(nowPlayingInfo, error) {
          state.infoCompleted = true
          state.infoError = isNil(error)
            ? null
            : unwrap(error.localizedDescription)
          state.info = isNil(nowPlayingInfo) ? null : nowPlayingInfo
        }
      )
      const infoBridge = materializeNativeBlock(infoCallback)

      keepAlive.push(
        path,
        request,
        infoCallback,
        infoBridge.holder,
        infoBridge.block
      )
      $.objc_msgSend(request, infoSelector, infoBridge.block, null)

      if (request.respondsToSelector(isPlayingSelector)) {
        const isPlayingCallback = ObjC.block(
          ["void", ["bool", "id"]],
          function(isPlaying, error) {
            state.isPlayingCompleted = true
            state.isPlaying = isNil(error) ? Boolean(isPlaying) : false
          }
        )
        keepAlive.push(isPlayingCallback)
        $.objc_msgSend(
          request,
          isPlayingSelector,
          requestQueue,
          isPlayingCallback
        )
      } else {
        state.isPlayingCompleted = true
      }

      if (request.respondsToSelector(artworkSelector)) {
        const artworkCallback = ObjC.block(
          ["void", ["id", "id"]],
          function(nowPlayingArtwork, _) {
            state.artworkCompleted = true
            state.artwork = isNil(nowPlayingArtwork)
              ? null
              : nowPlayingArtwork
          }
        )
        const artworkBridge = materializeNativeBlock(artworkCallback)
        keepAlive.push(
          artworkCallback,
          artworkBridge.holder,
          artworkBridge.block
        )
        $.objc_msgSend(request, artworkSelector, artworkBridge.block, null)
      } else {
        state.artworkCompleted = true
      }

      if (request.respondsToSelector(lastPlayingDateSelector)) {
        const dateCallback = ObjC.block(
          ["void", ["id", "id"]],
          function(lastPlayingDate, _) {
            state.dateCompleted = true
            state.lastPlayingDate = dateSeconds(lastPlayingDate)
          }
        )
        const dateBridge = materializeNativeBlock(dateCallback)
        keepAlive.push(dateCallback, dateBridge.holder, dateBridge.block)
        $.objc_msgSend(request, lastPlayingDateSelector, dateBridge.block, null)
      } else {
        state.dateCompleted = true
      }
    } catch (_) {
      // Keep the existing global provider behavior when a future macOS
      // release removes a targeted selector for one adapted player.
      state.infoCompleted = true
      state.isPlayingCompleted = true
      state.dateCompleted = true
      state.artworkCompleted = true
    }
  }

  const deadline = $.NSDate.dateWithTimeIntervalSinceNow(1.25)
  while (
    states.some(
      state =>
        !state.infoCompleted ||
        !state.isPlayingCompleted ||
        !state.dateCompleted ||
        !state.artworkCompleted
    ) &&
    Number(deadline.timeIntervalSinceNow) > 0
  ) {
    $.NSRunLoop.currentRunLoop.runUntilDate(
      $.NSDate.dateWithTimeIntervalSinceNow(0.02)
    )
  }

  // Once the player-scoped API has accepted a request, never revive a
  // stale playbackRate when its callback fails to arrive by the deadline.
  // A later poll can restore playing state from a fresh response.
  for (const state of states) {
    if (!state.isPlayingCompleted) {
      state.isPlaying = false
      state.isPlayingCompleted = true
    }
  }

  for (const state of states) {
    if (
      state.infoCompleted &&
      state.infoError === null &&
      !isNil(state.info)
    ) {
      candidates.push(
        snapshot(
          state.info,
          state.bundleIdentifier,
          "supported",
          state.isPlaying,
          state.lastPlayingDate,
          state.artwork
        )
      )
    }
  }

  return JSON.stringify({
    candidates: candidates,
    complete: states.every(
      state => state.infoCompleted && state.isPlayingCompleted
    )
  })
}

