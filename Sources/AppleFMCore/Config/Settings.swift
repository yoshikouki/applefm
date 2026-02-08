import Foundation

/// 設定キーのメタデータ
public struct KeyMetadata: Sendable {
    public let key: String
    public let type: String
    public let description: String
    public let validValues: [String]?
    public let range: String?
}

/// CLI オプションのデフォルト値を保持する設定モデル
public struct Settings: Codable, Sendable, Equatable {
    public var maxTokens: Int?
    public var temperature: Double?
    public var sampling: String?
    public var samplingThreshold: Double?
    public var samplingTop: Int?
    public var samplingSeed: UInt64?
    public var guardrails: String?
    public var adapter: String?
    public var tools: [String]?
    public var toolApproval: String?
    public var format: String?
    public var stream: Bool?
    public var instructions: String?
    public var logEnabled: Bool?
    public var language: String?
    public var rawJson: Bool?

    public init(
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        sampling: String? = nil,
        samplingThreshold: Double? = nil,
        samplingTop: Int? = nil,
        samplingSeed: UInt64? = nil,
        guardrails: String? = nil,
        adapter: String? = nil,
        tools: [String]? = nil,
        toolApproval: String? = nil,
        format: String? = nil,
        stream: Bool? = nil,
        instructions: String? = nil,
        logEnabled: Bool? = nil,
        language: String? = nil,
        rawJson: Bool? = nil
    ) {
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.sampling = sampling
        self.samplingThreshold = samplingThreshold
        self.samplingTop = samplingTop
        self.samplingSeed = samplingSeed
        self.guardrails = guardrails
        self.adapter = adapter
        self.tools = tools
        self.toolApproval = toolApproval
        self.format = format
        self.stream = stream
        self.instructions = instructions
        self.logEnabled = logEnabled
        self.language = language
        self.rawJson = rawJson
    }

    /// 有効な設定キー一覧
    public static let validKeys: Set<String> = [
        "maxTokens", "temperature", "sampling", "samplingThreshold",
        "samplingTop", "samplingSeed", "guardrails", "adapter",
        "tools", "toolApproval", "format", "stream", "instructions", "logEnabled",
        "language", "rawJson",
    ]

    /// キー名で値を取得
    public func value(forKey key: String) -> String? {
        switch key {
        case "maxTokens": return maxTokens.map(String.init)
        case "temperature": return temperature.map { "\($0)" }
        case "sampling": return sampling
        case "samplingThreshold": return samplingThreshold.map { "\($0)" }
        case "samplingTop": return samplingTop.map(String.init)
        case "samplingSeed": return samplingSeed.map { "\($0)" }
        case "guardrails": return guardrails
        case "adapter": return adapter
        case "tools": return tools?.joined(separator: ",")
        case "toolApproval": return toolApproval
        case "format": return format
        case "stream": return stream.map { "\($0)" }
        case "instructions": return instructions
        case "logEnabled": return logEnabled.map { "\($0)" }
        case "language": return language
        case "rawJson": return rawJson.map { "\($0)" }
        default: return nil
        }
    }

    /// キー名で値を設定
    public mutating func setValue(_ value: String, forKey key: String) throws {
        switch key {
        case "maxTokens":
            guard let v = Int(value) else { throw AppError.invalidInput("'\(value)' is not a valid integer.") }
            maxTokens = v
        case "temperature":
            guard let v = Double(value) else { throw AppError.invalidInput("'\(value)' is not a valid number.") }
            guard v >= 0.0 && v <= 2.0 else { throw AppError.invalidInput("temperature must be between 0.0 and 2.0.") }
            temperature = v
        case "sampling":
            let valid = ["greedy"]
            guard valid.contains(value) else { throw AppError.invalidInput("Invalid value '\(value)' for sampling. Valid values: \(valid.joined(separator: ", "))") }
            sampling = value
        case "samplingThreshold":
            guard let v = Double(value) else { throw AppError.invalidInput("'\(value)' is not a valid number.") }
            guard v >= 0.0 && v <= 1.0 else { throw AppError.invalidInput("samplingThreshold must be between 0.0 and 1.0.") }
            samplingThreshold = v
        case "samplingTop":
            guard let v = Int(value) else { throw AppError.invalidInput("'\(value)' is not a valid integer.") }
            samplingTop = v
        case "samplingSeed":
            guard let v = UInt64(value) else { throw AppError.invalidInput("'\(value)' is not a valid unsigned integer.") }
            samplingSeed = v
        case "guardrails":
            let valid = ["default", "permissive"]
            guard valid.contains(value) else { throw AppError.invalidInput("Invalid value '\(value)' for guardrails. Valid values: \(valid.joined(separator: ", "))") }
            guardrails = value
        case "adapter":
            adapter = value
        case "tools":
            let validTools = ["shell", "file-read"]
            let parsed = value.split(separator: ",").map(String.init)
            for t in parsed {
                guard validTools.contains(t) else { throw AppError.invalidInput("Invalid tool '\(t)'. Valid values: \(validTools.joined(separator: ", "))") }
            }
            tools = parsed
        case "toolApproval":
            let valid = ["ask", "auto"]
            guard valid.contains(value) else { throw AppError.invalidInput("Invalid value '\(value)' for toolApproval. Valid values: \(valid.joined(separator: ", "))") }
            toolApproval = value
        case "format":
            let valid = ["text", "json"]
            guard valid.contains(value) else { throw AppError.invalidInput("Invalid value '\(value)' for format. Valid values: \(valid.joined(separator: ", "))") }
            format = value
        case "stream":
            guard let v = Bool(value) else { throw AppError.invalidInput("'\(value)' is not a valid boolean (true/false).") }
            stream = v
        case "instructions":
            instructions = value
        case "logEnabled":
            guard let v = Bool(value) else { throw AppError.invalidInput("'\(value)' is not a valid boolean (true/false).") }
            logEnabled = v
        case "language":
            let valid = ["ja", "en"]
            guard valid.contains(value) else { throw AppError.invalidInput("Invalid value '\(value)' for language. Valid values: \(valid.joined(separator: ", "))") }
            language = value
        case "rawJson":
            guard let v = Bool(value) else { throw AppError.invalidInput("'\(value)' is not a valid boolean (true/false).") }
            rawJson = v
        default:
            if let suggestion = Settings.suggestKey(for: key) {
                throw AppError.invalidInput("Unknown setting key: '\(key)'. Did you mean '\(suggestion)'?")
            }
            throw AppError.invalidInput("Unknown setting key: '\(key)'. Valid keys: \(Settings.validKeys.sorted().joined(separator: ", "))")
        }
    }

    /// キー名で値をリセット
    public mutating func removeValue(forKey key: String) throws {
        guard Settings.validKeys.contains(key) else {
            throw AppError.invalidInput("Unknown setting key: '\(key)'. Valid keys: \(Settings.validKeys.sorted().joined(separator: ", "))")
        }
        switch key {
        case "maxTokens": maxTokens = nil
        case "temperature": temperature = nil
        case "sampling": sampling = nil
        case "samplingThreshold": samplingThreshold = nil
        case "samplingTop": samplingTop = nil
        case "samplingSeed": samplingSeed = nil
        case "guardrails": guardrails = nil
        case "adapter": adapter = nil
        case "tools": tools = nil
        case "toolApproval": toolApproval = nil
        case "format": format = nil
        case "stream": stream = nil
        case "instructions": instructions = nil
        case "logEnabled": logEnabled = nil
        case "language": language = nil
        case "rawJson": rawJson = nil
        default: break
        }
    }

    /// 全設定をキー/値ペアとして返す（値が設定されているもののみ）
    public func allValues() -> [(key: String, value: String)] {
        var result: [(key: String, value: String)] = []
        for key in Settings.validKeys.sorted() {
            if let v = value(forKey: key) {
                result.append((key: key, value: v))
            }
        }
        return result
    }

    // MARK: - Key Metadata

    public static let keyMetadata: [String: KeyMetadata] = {
        let items: [KeyMetadata] = [
            KeyMetadata(key: "maxTokens", type: "integer", description: "Maximum number of tokens to generate", validValues: nil, range: nil),
            KeyMetadata(key: "temperature", type: "number", description: "Sampling temperature", validValues: nil, range: "0.0-2.0"),
            KeyMetadata(key: "sampling", type: "string", description: "Sampling strategy", validValues: ["greedy"], range: nil),
            KeyMetadata(key: "samplingThreshold", type: "number", description: "Probability threshold for random sampling", validValues: nil, range: "0.0-1.0"),
            KeyMetadata(key: "samplingTop", type: "integer", description: "Top-k value for random sampling", validValues: nil, range: nil),
            KeyMetadata(key: "samplingSeed", type: "integer", description: "Random seed for sampling", validValues: nil, range: nil),
            KeyMetadata(key: "guardrails", type: "string", description: "Content guardrails level", validValues: ["default", "permissive"], range: nil),
            KeyMetadata(key: "adapter", type: "string", description: "Model adapter identifier", validValues: nil, range: nil),
            KeyMetadata(key: "tools", type: "list", description: "Comma-separated list of tools to enable", validValues: ["shell", "file-read"], range: nil),
            KeyMetadata(key: "toolApproval", type: "string", description: "Tool execution approval mode", validValues: ["ask", "auto"], range: nil),
            KeyMetadata(key: "format", type: "string", description: "Output format", validValues: ["text", "json"], range: nil),
            KeyMetadata(key: "stream", type: "boolean", description: "Enable streaming output", validValues: ["true", "false"], range: nil),
            KeyMetadata(key: "instructions", type: "string", description: "System instructions for the model", validValues: nil, range: nil),
            KeyMetadata(key: "logEnabled", type: "boolean", description: "Enable command history and session logging", validValues: ["true", "false"], range: nil),
            KeyMetadata(key: "language", type: "string", description: "Default response language hint", validValues: ["ja", "en"], range: nil),
            KeyMetadata(key: "rawJson", type: "boolean", description: "Output raw JSON without content wrapper (generate commands)", validValues: ["true", "false"], range: nil),
        ]
        var dict: [String: KeyMetadata] = [:]
        for item in items { dict[item.key] = item }
        return dict
    }()

    /// Levenshtein 距離でキー候補を提示
    public static func suggestKey(for input: String) -> String? {
        var best: (key: String, distance: Int)?
        for key in validKeys {
            let d = levenshteinDistance(input, key)
            if d <= 3, best == nil || d < best!.distance {
                best = (key, d)
            }
        }
        return best?.key
    }

    private static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        let m = a.count, n = b.count
        if m == 0 { return n }
        if n == 0 { return m }
        var prev = Array(0...n)
        var curr = [Int](repeating: 0, count: n + 1)
        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
            }
            prev = curr
        }
        return prev[n]
    }

    /// ログが有効かどうか（デフォルト true、環境変数 APPLEFM_NO_LOG でも無効化可能）
    public var isLogEnabled: Bool {
        if ProcessInfo.processInfo.environment["APPLEFM_NO_LOG"] != nil { return false }
        return logEnabled ?? true
    }

    // MARK: - Effective Instructions

    /// CLI の --instructions/--language と settings の instructions/language を統合する
    public func effectiveInstructions(cliInstructions: String?, cliLanguage: String?) -> String? {
        let base = cliInstructions ?? instructions
        let langHint: String? = switch cliLanguage ?? language {
        case "ja": "Respond in Japanese."
        case "en": "Respond in English."
        default: nil
        }
        return switch (langHint, base) {
        case let (h?, b?): "\(h) \(b)"
        case let (h?, nil): h
        case (nil, let b): b
        }
    }

    // MARK: - Presets

    public struct Preset: Sendable {
        public let name: String
        public let description: String
        public let values: [(key: String, value: String)]
    }

    public static let presets: [Preset] = [
        Preset(name: "creative", description: "High temperature for creative generation", values: [("temperature", "1.5")]),
        Preset(name: "precise", description: "Low temperature with greedy sampling", values: [("temperature", "0.2"), ("sampling", "greedy")]),
        Preset(name: "balanced", description: "Moderate temperature for balanced output", values: [("temperature", "0.7")]),
    ]
}
