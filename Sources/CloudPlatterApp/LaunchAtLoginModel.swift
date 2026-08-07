import Combine
import Foundation

@MainActor
final class LaunchAtLoginModel: ObservableObject {
    @Published private(set) var status: LaunchAtLoginStatus = .disabled
    @Published private(set) var feedbackMessage: String?

    private let service: any LaunchAtLoginServicing
    private let isInstalledInApplications: Bool

    init(
        service: any LaunchAtLoginServicing = SystemLaunchAtLoginService(),
        bundleURL: URL = Bundle.main.bundleURL
    ) {
        self.service = service
        isInstalledInApplications = bundleURL.pathComponents.starts(
            with: ["/", "Applications"]
        )
        refresh()
    }

    var isEnabled: Bool {
        status == .enabled
    }

    var canChangeRegistration: Bool {
        status == .disabled || status == .enabled
    }

    var statusMessage: String {
        switch status {
        case .disabled:
            "登录这台 Mac 后不会自动启动。"
        case .enabled:
            "登录这台 Mac 后会自动恢复桌面唱机场景。"
        case .requiresApproval:
            "macOS 需要你在“系统设置 → 通用 → 登录项”中允许 CloudPlatter。"
        case .unavailable:
            "请先把 CloudPlatter 放入“应用程序”文件夹，再启用登录时启动。"
        }
    }

    func setEnabled(_ shouldEnable: Bool) {
        feedbackMessage = nil

        guard isInstalledInApplications else {
            status = .unavailable
            return
        }

        do {
            if shouldEnable {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            // 系统错误可能包含本地路径，界面只展示稳定且不泄露环境信息的反馈。
            feedbackMessage =
                shouldEnable
                ? "暂时无法添加登录项，请稍后重试或前往系统设置手动添加。"
                : "暂时无法移除登录项，请前往系统设置检查。"
        }

        refresh()
    }

    func refresh() {
        guard isInstalledInApplications else {
            status = .unavailable
            return
        }
        status = service.status
    }

    func openSystemSettings() {
        service.openSystemSettings()
    }
}
