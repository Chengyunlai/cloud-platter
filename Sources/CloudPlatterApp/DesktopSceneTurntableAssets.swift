import AppKit
import SwiftUI

/// 集中读取用户提供并完成透明化处理的唱机部件素材。
enum DesktopSceneTurntableAsset: String, CaseIterable {
    case deck = "turntable-deck"
    case knob = "turntable-knob"
    case plaque = "turntable-plaque"
    case tonearm = "turntable-tonearm"
    case pivot = "turntable-pivot"
    case cartridge = "turntable-cartridge"
    case headshell = "turntable-headshell"

    @MainActor
    var image: Image? {
        guard let image = Self.cachedImages[self] ?? nil else {
            return nil
        }
        return Image(nsImage: image)
    }

    var moduleResourceURL: URL? {
        Bundle.module.url(
            forResource: rawValue,
            withExtension: "png",
            subdirectory: "Turntable"
        ) ?? Bundle.module.url(forResource: rawValue, withExtension: "png")
    }

    @MainActor
    private static let cachedImages: [Self: NSImage?] = {
        Dictionary(
            uniqueKeysWithValues: allCases.map { asset in
                let packagedURL = Bundle.main.url(
                    forResource: asset.rawValue,
                    withExtension: "png",
                    subdirectory: "Visuals/Turntable"
                )
                let url = packagedURL ?? asset.moduleResourceURL
                return (asset, url.flatMap(NSImage.init(contentsOf:)))
            })
    }()
}
