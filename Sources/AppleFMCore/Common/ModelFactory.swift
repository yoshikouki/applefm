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

    public static func makeGenerationOptions(
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) -> GenerationOptions {
        var options = GenerationOptions()
        if let maxTokens {
            options.maximumResponseTokens = maxTokens
        }
        if let temperature {
            options.temperature = temperature
        }
        return options
    }
}
