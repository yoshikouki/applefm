import AppleFMCore
import ArgumentParser

do {
    var command = try AppleFM.parseAsRoot()
    if var asyncCommand = command as? any AsyncParsableCommand {
        // Generic function で implicit existential opening を利用し、
        // concrete type の async run() に正しくディスパッチする。
        // any AsyncParsableCommand に直接 .run() を呼ぶと Swift 6.2 では
        // sync 版 ParsableCommand.run() が選択されてしまうため。
        try await executeAsync(&asyncCommand)
    } else {
        try command.run()
    }
} catch {
    AppleFM.exit(withError: error)
}

func executeAsync<C: AsyncParsableCommand>(_ command: inout C) async throws {
    try await command.run()
}
