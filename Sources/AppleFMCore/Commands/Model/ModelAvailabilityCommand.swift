import ArgumentParser
import FoundationModels

struct ModelAvailabilityCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "availability",
        abstract: "Check model availability"
    )

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let model = SystemLanguageModel.default
        let formatter = OutputFormatter(format: format)

        let status: String
        let details: String

        switch model.availability {
        case .available:
            status = "available"
            details = "Model is ready to use."
        case .unavailable(let reason):
            status = "unavailable"
            details = describeReason(reason)
        @unknown default:
            status = "unknown"
            details = "Unknown availability state."
        }

        print(formatter.output([
            "status": status,
            "details": details,
        ]))
    }

    private func describeReason(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Device is not eligible for Foundation Models."
        case .modelNotReady:
            return "Model is not yet downloaded or ready."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled."
        @unknown default:
            return "Unknown reason."
        }
    }
}
