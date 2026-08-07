import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

protocol LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus { get }

    func register() throws
    func unregister() throws
    func openSystemSettings()
}

struct SystemLaunchAtLoginService: LaunchAtLoginServicing {
    private let service = SMAppService.mainApp

    var status: LaunchAtLoginStatus {
        switch service.status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
