import AppleFMCore
import ArgumentParser

do {
    var command = try AppleFM.parseAsRoot()
    if var asyncCommand = command as? any AsyncParsableCommand {
        try await asyncCommand.run()
    } else {
        try command.run()
    }
} catch {
    AppleFM.exit(withError: error)
}
