import ArgumentParser
import Foundation
import FoundationModels

struct SessionGenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate structured output using a JSON schema"
    )

    @Argument(help: "Session name")
    var name: String

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @Option(name: .long, help: "Path to JSON schema file")
    var schema: String

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat?

    @Flag(name: .long, help: "Output raw JSON without content wrapper")
    var raw: Bool = false

    func run() async throws {
        let settings = SettingsStore().load()

        let effectiveFormat = format ?? settings.format.flatMap { OutputFormat(rawValue: $0) } ?? .json

        let store = SessionStore()

        let metadata = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        let guardrailsFallback = metadata.guardrails.flatMap { GuardrailsOption(rawValue: $0) } ?? .default
        let model = try modelOptions.withSettings(settings).createModel(fallbackGuardrails: guardrailsFallback)

        let session: LanguageModelSession
        if transcript.isEmpty, let instructions = metadata.instructions {
            session = LanguageModelSession(model: model, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model, transcript: transcript)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let generationSchema = try SchemaLoader.load(from: schema)
        let options = generationOptions.withSettings(settings).makeOptions()

        if settings.isLogEnabled {
            try? HistoryStore().append(HistoryEntry(sessionId: name, text: promptText))
            try? SessionLogger().log(SessionLogEntry(type: "user", text: promptText), sessionId: name)
        }

        // Save transcript even if generation fails (preserves partial conversation)
        defer { try? store.saveTranscript(session.transcript, name: name) }

        do {
            let response = try await session.respond(
                to: promptText,
                schema: generationSchema,
                options: options
            )

            let output = String(describing: response.content)
            let effectiveRaw = raw || settings.rawJson ?? false
            if effectiveRaw && effectiveFormat == .json {
                print(output)
            } else {
                let formatter = OutputFormatter(format: effectiveFormat)
                print(formatter.output(output))
            }
            if settings.isLogEnabled {
                try? SessionLogger().log(SessionLogEntry(type: "assistant", text: output), sessionId: name)
            }
        } catch {
            if settings.isLogEnabled {
                try? SessionLogger().log(SessionLogEntry(type: "error", message: "\(error)"), sessionId: name)
            }
            throw AppError.generationError(error)
        }
    }
}
