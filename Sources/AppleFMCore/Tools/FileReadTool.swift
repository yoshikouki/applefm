import Foundation
import FoundationModels

struct FileReadTool: Tool {
    let name = "file_read"
    let description = "Read the contents of a file at the given path"

    @Generable(description: "Arguments for file reading")
    struct Arguments {
        @Guide(description: "Absolute or relative path to the file to read")
        var path: String
    }

    func call(arguments: Arguments) async throws -> String {
        let url = URL(fileURLWithPath: arguments.path)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
