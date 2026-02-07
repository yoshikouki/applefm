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
        instructions: String? = nil
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
    }

    /// 有効な設定キー一覧
    public static let validKeys: Set<String> = [
        "maxTokens", "temperature", "sampling", "samplingThreshold",
        "samplingTop", "samplingSeed", "guardrails", "adapter",
        "tools", "toolApproval", "format", "stream", "instructions",
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
            temperature = v
        case "sampling":
            sampling = value
        case "samplingThreshold":
            guard let v = Double(value) else { throw AppError.invalidInput("'\(value)' is not a valid number.") }
            samplingThreshold = v
        case "samplingTop":
            guard let v = Int(value) else { throw AppError.invalidInput("'\(value)' is not a valid integer.") }
            samplingTop = v
        case "samplingSeed":
            guard let v = UInt64(value) else { throw AppError.invalidInput("'\(value)' is not a valid unsigned integer.") }
            samplingSeed = v
        case "guardrails":
            guardrails = value
        case "adapter":
            adapter = value
        case "tools":
            tools = value.split(separator: ",").map(String.init)
        case "toolApproval":
            toolApproval = value
        case "format":
            format = value
        case "stream":
            guard let v = Bool(value) else { throw AppError.invalidInput("'\(value)' is not a valid boolean (true/false).") }
            stream = v
        case "instructions":
            instructions = value
        default:
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
}
