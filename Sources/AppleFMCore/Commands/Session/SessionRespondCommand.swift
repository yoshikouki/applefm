import ArgumentParser
import Foundation
import FoundationModels

struct SessionRespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "Send a prompt to a session and get a response"
    )

    @Argument(help: "Session name")
    var name: String

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup
    @OptionGroup var toolOptions: ToolOptionGroup

    @Flag(inversion: .prefixedNo, help: "Stream response incrementally")
    var stream: Bool?

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat?

    func validate() throws {
        if stream == true && format == .json {
            throw ValidationError("--stream and --format json cannot be used together.")
        }
    }

    func run() async throws {
        let settings = SettingsStore().load()

        let effectiveStream = stream ?? settings.stream ?? false
        let effectiveFormat = format ?? settings.format.flatMap { OutputFormat(rawValue: $0) } ?? .text

        if effectiveStream && effectiveFormat == .json {
            throw ValidationError("--stream and --format json cannot be used together.")
        }

        let store = SessionStore()

        let metadata = try store.loadMetadata(name: name)
        let transcript = try store.loadTranscript(name: name)

        // Use metadata values as fallbacks for model/tool options
        let guardrailsFallback = metadata.guardrails.flatMap { GuardrailsOption(rawValue: $0) } ?? .default
        let model = try modelOptions.withSettings(settings).createModel(fallbackGuardrails: guardrailsFallback)

        let effectiveToolOptions = toolOptions.withSettings(settings)
        let tools: [any Tool]
        if !effectiveToolOptions.tool.isEmpty {
            tools = try effectiveToolOptions.resolveTools()
        } else if let savedTools = metadata.tools, !savedTools.isEmpty {
            tools = try ToolRegistry.resolve(names: savedTools, approval: ToolApproval(mode: effectiveToolOptions.toolApproval))
        } else {
            tools = []
        }

        let session: LanguageModelSession
        if transcript.isEmpty, let instructions = metadata.instructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools, transcript: transcript)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let options = generationOptions.withSettings(settings).makeOptions()

        if settings.isLogEnabled {
            try? HistoryStore().append(HistoryEntry(sessionId: name, text: promptText))
            try? SessionLogger().log(SessionLogEntry(type: "user", text: promptText), sessionId: name)
        }

        // Save transcript even if generation fails (preserves partial conversation)
        defer { try? store.saveTranscript(session.transcript, name: name) }

        do {
            if effectiveStream {
                let responseStream = session.streamResponse(to: promptText, options: options)
                try await ResponseStreamer.stream(responseStream)
            } else {
                let response = try await session.respond(to: promptText, options: options)
                let formatter = OutputFormatter(format: effectiveFormat)
                print(formatter.output(response.content))
                if settings.isLogEnabled {
                    try? SessionLogger().log(SessionLogEntry(type: "assistant", text: response.content), sessionId: name)
                }
            }
        } catch {
            if settings.isLogEnabled {
                try? SessionLogger().log(SessionLogEntry(type: "error", message: "\(error)"), sessionId: name)
            }
            throw AppError.generationError(error)
        }
    }
}
