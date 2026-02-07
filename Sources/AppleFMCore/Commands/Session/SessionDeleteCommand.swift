import ArgumentParser
import Darwin
import Foundation

struct SessionDeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a session"
    )

    @Argument(help: "Session name to delete")
    var name: String

    @Flag(name: .long, help: "Skip confirmation prompt")
    var force: Bool = false

    func run() async throws {
        let store = SessionStore()

        guard store.sessionExists(name: name) else {
            throw AppError.sessionNotFound(name)
        }

        if !force {
            guard isatty(fileno(Darwin.stdin)) != 0 else {
                throw AppError.invalidInput("Use --force to delete sessions in non-interactive mode.")
            }
            FileHandle.standardError.write(
                Data("Delete session '\(name)'? [y/N] ".utf8)
            )
            guard let input = readLine()?.lowercased(), input == "y" || input == "yes" else {
                print("Cancelled.")
                return
            }
        }

        try store.deleteSession(name: name)
        try? SessionLogger().deleteLog(sessionId: name)
        print("Session '\(name)' deleted.")
    }
}
