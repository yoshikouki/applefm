import ArgumentParser
import Foundation

struct ConfigInitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Interactive setup wizard for settings"
    )

    private struct PromptItem {
        let key: String
        let label: String
        let hint: String
    }

    func run() async throws {
        let store = SettingsStore()
        var settings = store.load()

        let prompts: [PromptItem] = [
            PromptItem(key: "stream", label: "Enable streaming output?", hint: "true/false"),
            PromptItem(key: "format", label: "Output format?", hint: "text/json"),
            PromptItem(key: "temperature", label: "Temperature?", hint: "0.0-2.0"),
            PromptItem(key: "maxTokens", label: "Max tokens?", hint: "integer"),
            PromptItem(key: "guardrails", label: "Guardrails level?", hint: "default/permissive"),
            PromptItem(key: "tools", label: "Tools to enable?", hint: "shell,file-read"),
            PromptItem(key: "toolApproval", label: "Tool approval mode?", hint: "ask/auto"),
        ]

        FileHandle.standardError.write(Data("Interactive setup (press Enter to skip)\n\n".utf8))

        for prompt in prompts {
            let current = settings.value(forKey: prompt.key)
            let defaultStr = current.map { " [\($0)]" } ?? ""
            FileHandle.standardError.write(Data("\(prompt.label) (\(prompt.hint))\(defaultStr): ".utf8))

            guard let line = readLine()?.trimmingCharacters(in: .whitespaces), !line.isEmpty else {
                continue
            }
            try settings.setValue(line, forKey: prompt.key)
        }

        try store.save(settings)
        FileHandle.standardError.write(Data("\nSettings saved.\n".utf8))
    }
}
