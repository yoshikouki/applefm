import ArgumentParser
import Foundation

struct SessionListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all sessions"
    )

    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    func run() async throws {
        let store = SessionStore()
        let sessions = try store.listSessions()

        if sessions.isEmpty {
            print("No sessions found.")
            return
        }

        let formatter = OutputFormatter(format: format)
        switch format {
        case .text:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let lines = sessions.map { meta in
                let date = dateFormatter.string(from: meta.createdAt)
                let instructions = meta.instructions.map { " (\($0.prefix(40))...)" } ?? ""
                return "\(meta.name)  \(date)\(instructions)"
            }
            print(lines.joined(separator: "\n"))
        case .json:
            print(formatter.outputEncodable(sessions))
        }
    }
}
