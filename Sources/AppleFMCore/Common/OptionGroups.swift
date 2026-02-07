import ArgumentParser
import FoundationModels

// MARK: - ExpressibleByArgument conformance

extension OutputFormat: ExpressibleByArgument {}

// MARK: - Generation Options

struct GenerationOptionGroup: ParsableArguments {
    @Option(name: .long, help: "Maximum response tokens")
    var maxTokens: Int?

    @Option(name: .long, help: "Temperature for sampling (0.0-2.0)")
    var temperature: Double?

    @Option(name: .long, help: "Sampling mode (greedy)")
    var sampling: SamplingModeOption?

    @Option(name: .long, help: "Random sampling probability threshold (0.0-1.0)")
    var samplingThreshold: Double?

    @Option(name: .long, help: "Random sampling top-k count")
    var samplingTop: Int?

    @Option(name: .long, help: "Random sampling seed")
    var samplingSeed: UInt64?

    func makeOptions() -> GenerationOptions {
        let samplingMode = ModelFactory.resolveSamplingMode(
            mode: sampling, threshold: samplingThreshold, top: samplingTop, seed: samplingSeed
        )
        return ModelFactory.makeGenerationOptions(maxTokens: maxTokens, temperature: temperature, sampling: samplingMode)
    }

    /// Settings の値で未指定フィールドを埋めたコピーを返す
    func withSettings(_ settings: Settings) -> GenerationOptionGroup {
        var copy = self
        if copy.maxTokens == nil { copy.maxTokens = settings.maxTokens }
        if copy.temperature == nil { copy.temperature = settings.temperature }
        if copy.sampling == nil { copy.sampling = settings.sampling.flatMap { SamplingModeOption(rawValue: $0) } }
        if copy.samplingThreshold == nil { copy.samplingThreshold = settings.samplingThreshold }
        if copy.samplingTop == nil { copy.samplingTop = settings.samplingTop }
        if copy.samplingSeed == nil { copy.samplingSeed = settings.samplingSeed }
        return copy
    }
}

// MARK: - Model Options

struct ModelOptionGroup: ParsableArguments {
    @Option(name: .long, help: "Guardrails level (default or permissive)")
    var guardrails: GuardrailsOption?

    @Option(name: .long, help: "Path to adapter file")
    var adapter: String?

    func createModel(fallbackGuardrails: GuardrailsOption = .default) throws -> SystemLanguageModel {
        try ModelFactory.createModel(guardrails: guardrails ?? fallbackGuardrails, adapterPath: adapter)
    }

    func withSettings(_ settings: Settings) -> ModelOptionGroup {
        var copy = self
        if copy.guardrails == nil { copy.guardrails = settings.guardrails.flatMap { GuardrailsOption(rawValue: $0) } }
        if copy.adapter == nil { copy.adapter = settings.adapter }
        return copy
    }
}

// MARK: - Tool Options

struct ToolOptionGroup: ParsableArguments {
    @Option(name: .long, help: "Enable built-in tool (shell, file-read). Repeatable.")
    var tool: [String] = []

    @Option(name: .long, help: "Tool approval mode (ask or auto)")
    var toolApproval: ToolApprovalMode?

    func resolveTools() throws -> [any Tool] {
        try ToolRegistry.resolve(names: tool, approval: ToolApproval(mode: toolApproval ?? .ask))
    }

    func withSettings(_ settings: Settings) -> ToolOptionGroup {
        var copy = self
        if copy.tool.isEmpty { copy.tool = settings.tools ?? [] }
        if copy.toolApproval == nil {
            copy.toolApproval = settings.toolApproval.flatMap { ToolApprovalMode(rawValue: $0) }
        }
        return copy
    }
}
