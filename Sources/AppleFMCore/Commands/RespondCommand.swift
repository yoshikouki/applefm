import ArgumentParser
import Darwin
import Foundation
import FoundationModels

struct RespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "One-shot response (creates a temporary session)"
    )

    @Argument(help: "Prompt text")
    var prompt: String?

    @Option(name: .long, help: "Read prompt from file")
    var file: String?

    @Option(name: .long, help: "System instructions")
    var instructions: String?

    @Option(name: .long, help: "Response language hint (ja, en)")
    var language: String?

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

        let genOpts = generationOptions.withSettings(settings)
        let tools = try toolOptions.withSettings(settings).resolveTools()
        let effectiveInstructions = settings.effectiveInstructions(cliInstructions: instructions, cliLanguage: language)

        // No prompt + no file + TTY → interactive mode
        if prompt == nil && file == nil && isatty(fileno(Darwin.stdin)) != 0 {
            let chatInstructions = effectiveInstructions ?? InteractiveLoop.defaultInstructions
            let chatModel = try modelOptions.withSettings(settings).createModel(fallbackGuardrails: .permissive)
            let chatSession = LanguageModelSession(model: chatModel, tools: tools, instructions: chatInstructions)

            let sessionName = InteractiveLoop.generateSessionName()
            let store = SessionStore()

            let metadata = SessionMetadata(
                name: sessionName,
                instructions: chatInstructions,
                guardrails: modelOptions.guardrails?.rawValue,
                adapterPath: modelOptions.adapter,
                tools: toolOptions.tool.isEmpty ? nil : toolOptions.tool
            )
            try store.saveMetadata(metadata)
            try store.saveTranscript(chatSession.transcript, name: sessionName)

            let options = genOpts.makeOptions()

            await InteractiveLoop().run(
                session: chatSession,
                sessionName: sessionName,
                store: store,
                options: options,
                settings: settings
            )
            return
        }

        let model = try modelOptions.withSettings(settings).createModel()
        let session: LanguageModelSession
        if let effectiveInstructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: effectiveInstructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools)
        }

        let promptText = try PromptInput.resolve(argument: prompt, filePath: file)
        let options = genOpts.makeOptions()

        if settings.isLogEnabled {
            try? HistoryStore().append(HistoryEntry(sessionId: UUID().uuidString, text: promptText))
        }

        do {
            if effectiveStream {
                let responseStream = session.streamResponse(to: promptText, options: options)
                try await ResponseStreamer.stream(responseStream)
            } else {
                let response = try await session.respond(to: promptText, options: options)
                let formatter = OutputFormatter(format: effectiveFormat)
                print(formatter.output(response.content))
            }
        } catch {
            throw AppError.generationError(error)
        }
    }
}
