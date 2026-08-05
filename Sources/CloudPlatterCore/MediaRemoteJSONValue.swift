import Foundation

/// 保留 MediaRemote JSON 的值类型，避免私有字段结构泄漏到适配层之外。
enum MediaRemoteJSONValue: Decodable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: MediaRemoteJSONValue])
    case array([MediaRemoteJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: MediaRemoteJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([MediaRemoteJSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "无法识别 JSON 值类型。"
            )
        }
    }
}

extension Dictionary where Key == String, Value == MediaRemoteJSONValue {
    func mediaRemoteString(for key: String) -> String? {
        guard case .string(let value) = self[key] else {
            return nil
        }
        return value
    }

    func mediaRemoteBool(for key: String) -> Bool? {
        guard case .bool(let value) = self[key] else {
            return nil
        }
        return value
    }

    func mediaRemoteNumber(for key: String) -> Double? {
        guard case .number(let value) = self[key] else {
            return nil
        }
        return value
    }
}
