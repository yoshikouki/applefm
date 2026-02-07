import Foundation
import FoundationModels

/// GenerationError をユーザー向けメッセージと終了コードに変換する
public enum AppError: Error, LocalizedError {
    case modelNotAvailable(String)
    case generationError(any Error)
    case sessionNotFound(String)
    case invalidInput(String)
    case fileError(String)

    public var errorDescription: String? { message }

    public var message: String {
        switch self {
        case .modelNotAvailable(let reason):
            return "Foundation Models is not available: \(reason)"
        case .generationError(let error):
            return Self.formatGenerationError(error)
        case .sessionNotFound(let name):
            return "Session not found: \(name)"
        case .invalidInput(let detail):
            return "Invalid input: \(detail)"
        case .fileError(let detail):
            return "File error: \(detail)"
        }
    }

    public var exitCode: Int32 {
        switch self {
        case .modelNotAvailable: return 10
        case .generationError(let error): return Self.exitCodeForGenerationError(error)
        case .sessionNotFound: return 1
        case .invalidInput: return 1
        case .fileError: return 1
        }
    }

    private static func formatGenerationError(_ error: any Error) -> String {
        if let genError = error as? LanguageModelSession.GenerationError {
            switch genError {
            case .exceededContextWindowSize:
                return "Context window exceeded. Start a new session or reduce prompt size."
            case .guardrailViolation:
                return "Request was blocked by safety guardrails."
            case .rateLimited:
                return "Rate limited. Please wait and try again."
            case .refusal:
                return "Model refused the request."
            case .unsupportedLanguageOrLocale:
                return "Unsupported language or locale."
            case .assetsUnavailable:
                return "Model assets are unavailable."
            case .unsupportedGuide:
                return "Unsupported generation guide."
            case .decodingFailure:
                return "Failed to decode generated content."
            case .concurrentRequests:
                return "Concurrent requests are not supported. Wait for the current request to finish."
            @unknown default:
                return "Generation error: \(error.localizedDescription)"
            }
        }
        return "Error: \(error.localizedDescription)"
    }

    private static func exitCodeForGenerationError(_ error: any Error) -> Int32 {
        if let genError = error as? LanguageModelSession.GenerationError {
            switch genError {
            case .exceededContextWindowSize: return 2
            case .guardrailViolation: return 3
            case .rateLimited: return 4
            case .refusal: return 5
            case .unsupportedLanguageOrLocale: return 6
            case .assetsUnavailable: return 7
            case .unsupportedGuide: return 8
            case .decodingFailure: return 9
            case .concurrentRequests: return 11
            @unknown default: return 1
            }
        }
        return 1
    }
}
