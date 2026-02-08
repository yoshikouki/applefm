import Darwin
import Foundation
import FoundationModels

/// REPL エンジン。DI seam で testability を確保
public struct InteractiveLoop: Sendable {
    public static let defaultInstructions = "You are a helpful assistant. Respond naturally and conversationally. Answer in the same language the user writes in."
    let readInput: @Sendable () -> String?
    let writeStderr: @Sendable (String) -> Void

    public init(
        readInput: @escaping @Sendable () -> String? = { Swift.readLine() },
        writeStderr: @escaping @Sendable (String) -> Void = { message in
            FileHandle.standardError.write(Data(message.utf8))
        }
    ) {
        self.readInput = readInput
        self.writeStderr = writeStderr
    }

    public func run(
        session: LanguageModelSession,
        sessionName: String,
        store: SessionStore,
        options: GenerationOptions,
        settings: Settings
    ) async {
        writeStderr("applefm interactive mode (session: \(sessionName))\n")
        writeStderr("Type /help for commands, /quit or Ctrl+D to exit.\n\n")

        while true {
            writeStderr(">>> ")

            guard let line = readInput() else {
                // EOF (Ctrl+D)
                break
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                continue
            }

            // Handle slash commands
            if trimmed.hasPrefix("/") {
                let shouldBreak = handleSlashCommand(trimmed, sessionName: sessionName)
                if shouldBreak {
                    break
                }
                continue
            }

            if settings.isLogEnabled {
                try? HistoryStore().append(HistoryEntry(sessionId: sessionName, text: trimmed))
                try? SessionLogger().log(SessionLogEntry(type: "user", text: trimmed), sessionId: sessionName)
            }

            do {
                let responseStream = session.streamResponse(to: trimmed, options: options)
                let finalText = try await ResponseStreamer.stream(responseStream)
                if settings.isLogEnabled {
                    try? SessionLogger().log(SessionLogEntry(type: "assistant", text: finalText), sessionId: sessionName)
                }
            } catch {
                let appError = AppError.generationError(error)
                writeStderr("[error] \(appError.message)\n")
                if settings.isLogEnabled {
                    try? SessionLogger().log(SessionLogEntry(type: "error", message: "\(error)"), sessionId: sessionName)
                }
            }

            try? store.saveTranscript(session.transcript, name: sessionName)
        }

        writeStderr("\nGoodbye.\n")
    }

    /// Returns true if the loop should break (exit)
    public func handleSlashCommand(_ input: String, sessionName: String) -> Bool {
        switch input {
        case "/quit", "/exit":
            return true
        case "/help":
            writeStderr("""
            Commands:
              /help     Show this help
              /session  Show current session name
              /quit     Exit interactive mode

            """)
        case "/session":
            writeStderr("Session: \(sessionName)\n")
        default:
            writeStderr("Unknown command: \(input). Type /help for available commands.\n")
        }
        return false
    }

    /// セッション名を自動生成: chat-YYYYMMDD-HHmmss
    public static func generateSessionName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "chat-\(formatter.string(from: Date()))"
    }
}
