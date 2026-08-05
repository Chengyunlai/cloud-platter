import Foundation

struct JXANowPlayingPaths: Sendable {
    let osascriptExecutable: URL
    let script: URL

    static func bundled(bundle: Bundle = .main) -> JXANowPlayingPaths {
        let resources = bundle.resourceURL ?? bundle.bundleURL
        return JXANowPlayingPaths(
            osascriptExecutable: URL(fileURLWithPath: "/usr/bin/osascript"),
            script:
                resources
                .appendingPathComponent("JXAFallback", isDirectory: true)
                .appendingPathComponent("netease-now-playing.js")
        )
    }
}
