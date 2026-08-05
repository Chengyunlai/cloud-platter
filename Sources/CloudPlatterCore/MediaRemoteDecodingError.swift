import Foundation

/// 描述 MediaRemote 快照或实时事件无法转换为规范化状态的原因。
public enum MediaRemoteDecodingError: Error, Equatable, Sendable {
    case invalidPayload
    case unsupportedEventType(String)
}
