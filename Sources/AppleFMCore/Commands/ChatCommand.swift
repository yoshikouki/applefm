import ArgumentParser
import Foundation
import FoundationModels

struct ChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Start an interactive chat session"
    )

    @Option(name: .long, help: "System instructions")
    var instructions: String?

    @Option(name: .long, help: "Response language hint (ja, en)")
    var language: String?

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup
    @OptionGroup var toolOptions: ToolOptionGroup

    func run() async throws {
        let settings = SettingsStore().load()
        let genOpts = generationOptions.withSettings(settings)
        let model = try modelOptions.withSettings(settings).createModel(fallbackGuardrails: .permissive)
        let tools = try toolOptions.withSettings(settings).resolveTools()
        let effectiveInstructions = settings.effectiveInstructions(cliInstructions: instructions, cliLanguage: language) ?? InteractiveLoop.defaultInstructions

        let session = LanguageModelSession(model: model, tools: tools, instructions: effectiveInstructions)

        let sessionName = InteractiveLoop.generateSessionName()
        let store = SessionStore()

        let metadata = SessionMetadata(
            name: sessionName,
            instructions: effectiveInstructions,
            guardrails: modelOptions.guardrails?.rawValue,
            adapterPath: modelOptions.adapter,
            tools: toolOptions.tool.isEmpty ? nil : toolOptions.tool
        )
        try store.saveMetadata(metadata)
        try store.saveTranscript(session.transcript, name: sessionName)

        let options = genOpts.makeOptions()

        await InteractiveLoop().run(
            session: session,
            sessionName: sessionName,
            store: store,
            options: options,
            settings: settings
        )
    }
}
