import ArgumentParser
import Foundation
import FoundationModels

public enum GuardrailsOption: String, CaseIterable, Sendable {
    case `default` = "default"
    case permissive = "permissive"

    public func toSystemGuardrails() -> SystemLanguageModel.Guardrails {
        switch self {
        case .default:
            return .default
        case .permissive:
            return .permissiveContentTransformations
        }
    }
}

extension GuardrailsOption: ExpressibleByArgument {}

public enum SamplingModeOption: String, CaseIterable, Sendable {
    case greedy
}

extension SamplingModeOption: ExpressibleByArgument {}

public enum ModelFactory {
    public static func createModel(
        guardrails: GuardrailsOption = .default,
        adapterPath: String? = nil
    ) throws -> SystemLanguageModel {
        let guardrailsValue = guardrails.toSystemGuardrails()
        let model: SystemLanguageModel
        if let adapterPath {
            let url = URL(fileURLWithPath: adapterPath)
            model = try SystemLanguageModel(adapter: .init(fileURL: url), guardrails: guardrailsValue)
        } else {
            model = SystemLanguageModel(useCase: .general, guardrails: guardrailsValue)
        }
        guard model.isAvailable else {
            throw AppError.modelNotAvailable("Model is not available.")
        }
        return model
    }

    public static func resolveSamplingMode(
        mode: SamplingModeOption? = nil,
        threshold: Double? = nil,
        top: Int? = nil,
        seed: UInt64? = nil
    ) -> GenerationOptions.SamplingMode? {
        if let mode {
            switch mode {
            case .greedy:
                return .greedy
            }
        }
        if let threshold {
            return .random(probabilityThreshold: threshold, seed: seed)
        }
        if let top {
            return .random(top: top, seed: seed)
        }
        return nil
    }

    public static func makeGenerationOptions(
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        sampling: GenerationOptions.SamplingMode? = nil
    ) -> GenerationOptions {
        var options = GenerationOptions()
        if let maxTokens {
            options.maximumResponseTokens = maxTokens
        }
        if let temperature {
            options.temperature = temperature
        }
        if let sampling {
            options.sampling = sampling
        }
        return options
    }
}
