import Combine
import Foundation

struct DesktopSceneDisplay: Identifiable, Equatable {
    let id: String
    let name: String
}

/// 保存桌面显示偏好；断开的显示器仍保留选择，不持久化任何播放内容。
@MainActor
final class DesktopSceneSettings: ObservableObject {
    @Published private(set) var isSceneVisible: Bool
    @Published private(set) var disabledDisplayIdentifiers: Set<String>
    @Published private(set) var availableDisplays: [DesktopSceneDisplay] = []

    private let defaults: UserDefaults
    private static let visibilityKey = "desktopSceneVisible"
    private static let disabledDisplaysKey = "desktopSceneDisabledDisplays"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isSceneVisible = defaults.object(forKey: Self.visibilityKey) as? Bool ?? true
        disabledDisplayIdentifiers = Set(
            defaults.stringArray(forKey: Self.disabledDisplaysKey) ?? []
        )
    }

    func setSceneVisible(_ isVisible: Bool) {
        guard isSceneVisible != isVisible else { return }
        isSceneVisible = isVisible
        defaults.set(isVisible, forKey: Self.visibilityKey)
    }

    func toggleSceneVisibility() {
        setSceneVisible(!isSceneVisible)
    }

    func isDisplayEnabled(_ identifier: String) -> Bool {
        !disabledDisplayIdentifiers.contains(identifier)
    }

    func setDisplayEnabled(_ isEnabled: Bool, identifier: String) {
        if isEnabled {
            disabledDisplayIdentifiers.remove(identifier)
        } else {
            disabledDisplayIdentifiers.insert(identifier)
        }
        defaults.set(
            disabledDisplayIdentifiers.sorted(), forKey: Self.disabledDisplaysKey
        )
    }

    func shouldShowScene(on identifier: String) -> Bool {
        isSceneVisible && isDisplayEnabled(identifier)
    }

    func updateAvailableDisplays(_ displays: [DesktopSceneDisplay]) {
        guard availableDisplays != displays else { return }
        availableDisplays = displays
    }
}
