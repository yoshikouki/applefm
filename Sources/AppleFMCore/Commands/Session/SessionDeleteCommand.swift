import ArgumentParser

struct SessionDeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a session"
    )

    @Argument(help: "Session name to delete")
    var name: String

    func run() async throws {
        let store = SessionStore()

        guard store.sessionExists(name: name) else {
            throw AppError.sessionNotFound(name)
        }

        try store.deleteSession(name: name)
        print("Session '\(name)' deleted.")
    }
}
