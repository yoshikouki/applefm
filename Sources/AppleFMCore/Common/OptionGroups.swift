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
}

// MARK: - Tool Options

struct ToolOptionGroup: ParsableArguments {
    @Option(name: .long, help: "Enable built-in tool (shell, file-read). Repeatable.")
    var tool: [String] = []

    @Option(name: .long, help: "Tool approval mode (ask or auto)")
    var toolApproval: ToolApprovalMode = .ask

    func resolveTools() throws -> [any Tool] {
        try ToolRegistry.resolve(names: tool, approval: ToolApproval(mode: toolApproval))
    }
}
