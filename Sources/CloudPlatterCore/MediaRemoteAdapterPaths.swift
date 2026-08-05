import Foundation

/// 定位应用包内 MediaRemote Adapter 所需的全部运行时资源。
struct MediaRemoteAdapterPaths: Equatable, Sendable {
    let perlExecutable: URL
    let supervisor: URL
    let script: URL
    let framework: URL
    let testClient: URL

    static func bundled(in bundle: Bundle = .main) -> Self {
        let resourceRoot =
            bundle.resourceURL ?? bundle.bundleURL.appendingPathComponent("Resources")
        let adapterRoot = resourceRoot.appendingPathComponent("MediaRemoteAdapter")

        return Self(
            perlExecutable: URL(fileURLWithPath: "/usr/bin/perl"),
            supervisor: adapterRoot.appendingPathComponent("mediaremote-supervisor.sh"),
            script: adapterRoot.appendingPathComponent("mediaremote-adapter.pl"),
            framework: adapterRoot.appendingPathComponent("MediaRemoteAdapter.framework"),
            testClient: adapterRoot.appendingPathComponent("MediaRemoteAdapterTestClient")
        )
    }
}
