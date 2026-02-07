import Foundation

/// 出力フォーマット
public enum OutputFormat: String, CaseIterable, Sendable {
    case text
    case json
}

/// text/json 出力のフォーマッタ
public struct OutputFormatter: Sendable {
    public let format: OutputFormat

    public init(format: OutputFormat = .text) {
        self.format = format
    }

    /// キー/値ペアを出力
    public func output(_ pairs: KeyValuePairs<String, String>) -> String {
        switch format {
        case .text:
            return pairs.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        case .json:
            let dict = Dictionary(pairs.map { ($0.key, $0.value) }, uniquingKeysWith: { _, last in last })
            guard let data = try? JSONSerialization.data(
                withJSONObject: dict,
                options: [.prettyPrinted, .sortedKeys]
            ) else {
                return "{}"
            }
            return String(data: data, encoding: .utf8) ?? "{}"
        }
    }

    /// 単一の値を出力
    public func output(_ value: String) -> String {
        switch format {
        case .text:
            return value
        case .json:
            let dict = ["content": value]
            guard let data = try? JSONSerialization.data(
                withJSONObject: dict,
                options: [.prettyPrinted]
            ) else {
                return "{}"
            }
            return String(data: data, encoding: .utf8) ?? "{}"
        }
    }

    /// リストを出力
    public func outputList(_ items: [String]) -> String {
        switch format {
        case .text:
            return items.joined(separator: "\n")
        case .json:
            guard let data = try? JSONSerialization.data(
                withJSONObject: items,
                options: [.prettyPrinted]
            ) else {
                return "[]"
            }
            return String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    /// Encodable な値を出力
    public func outputEncodable<T: Encodable>(_ value: T) -> String {
        switch format {
        case .text:
            return String(describing: value)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(value),
                  let string = String(data: data, encoding: .utf8) else {
                return "{}"
            }
            return string
        }
    }
}
