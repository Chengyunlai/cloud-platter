import Foundation
import Testing

@testable import CloudPlatterApp

@MainActor
@Suite("登录时启动设置")
struct LaunchAtLoginModelTests {
    @Test("已注册时展示开启状态")
    func registeredServiceIsEnabled() {
        let model = LaunchAtLoginModel(
            service: RecordingLaunchAtLoginService(status: .enabled),
            bundleURL: applicationsBundleURL
        )

        #expect(model.isEnabled)
        #expect(model.statusMessage.contains("自动恢复"))
    }

    @Test("开启后注册主应用并刷新状态")
    func enablingRegistersMainApplication() {
        let service = RecordingLaunchAtLoginService(status: .disabled)
        let model = LaunchAtLoginModel(
            service: service,
            bundleURL: applicationsBundleURL
        )

        model.setEnabled(true)

        #expect(service.registerCount == 1)
        #expect(model.status == .enabled)
    }

    @Test("关闭后移除主应用登录项")
    func disablingUnregistersMainApplication() {
        let service = RecordingLaunchAtLoginService(status: .enabled)
        let model = LaunchAtLoginModel(
            service: service,
            bundleURL: applicationsBundleURL
        )

        model.setEnabled(false)

        #expect(service.unregisterCount == 1)
        #expect(model.status == .disabled)
    }

    @Test("注册失败时只展示脱敏反馈")
    func registrationFailureUsesSanitizedFeedback() {
        let service = RecordingLaunchAtLoginService(
            status: .disabled,
            registerError: StubLaunchAtLoginError.rejected
        )
        let model = LaunchAtLoginModel(
            service: service,
            bundleURL: applicationsBundleURL
        )

        model.setEnabled(true)

        #expect(model.feedbackMessage?.contains("系统设置") == true)
        #expect(model.feedbackMessage?.contains("/private/") == false)
        #expect(model.status == .disabled)
    }

    @Test("应用程序目录外不尝试注册")
    func nonInstalledApplicationDoesNotRegister() {
        let service = RecordingLaunchAtLoginService(status: .disabled)
        let model = LaunchAtLoginModel(
            service: service,
            bundleURL: URL(fileURLWithPath: "/tmp/CloudPlatter.app")
        )

        model.setEnabled(true)

        #expect(model.status == .unavailable)
        #expect(service.registerCount == 0)
        #expect(model.statusMessage.contains("应用程序"))
    }

    @Test("需要批准时可以打开系统登录项设置")
    func approvalStateCanOpenSystemSettings() {
        let service = RecordingLaunchAtLoginService(status: .requiresApproval)
        let model = LaunchAtLoginModel(
            service: service,
            bundleURL: applicationsBundleURL
        )

        model.openSystemSettings()

        #expect(service.openSettingsCount == 1)
        #expect(!model.isEnabled)
        #expect(!model.canChangeRegistration)
    }

    private var applicationsBundleURL: URL {
        URL(fileURLWithPath: "/Applications/CloudPlatter.app")
    }
}

private final class RecordingLaunchAtLoginService: LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus
    private let registerError: (any Error)?
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0
    private(set) var openSettingsCount = 0

    init(
        status: LaunchAtLoginStatus,
        registerError: (any Error)? = nil
    ) {
        self.status = status
        self.registerError = registerError
    }

    func register() throws {
        registerCount += 1
        if let registerError {
            throw registerError
        }
        status = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        status = .disabled
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }
}

private enum StubLaunchAtLoginError: Error {
    case rejected
}
