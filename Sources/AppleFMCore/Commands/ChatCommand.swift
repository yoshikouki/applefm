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

    @OptionGroup var generationOptions: GenerationOptionGroup
    @OptionGroup var modelOptions: ModelOptionGroup
    @OptionGroup var toolOptions: ToolOptionGroup

    func run() async throws {
        let settings = SettingsStore().load()
        let genOpts = generationOptions.withSettings(settings)
        let model = try modelOptions.withSettings(settings).createModel()
        let tools = try toolOptions.withSettings(settings).resolveTools()
        let effectiveInstructions = instructions ?? settings.instructions

        let session: LanguageModelSession
        if let effectiveInstructions {
            session = LanguageModelSession(model: model, tools: tools, instructions: effectiveInstructions)
        } else {
            session = LanguageModelSession(model: model, tools: tools)
        }

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
