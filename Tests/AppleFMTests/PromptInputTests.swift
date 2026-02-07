import Testing
import Foundation
@testable import AppleFMCore

@Suite("PromptInput Tests")
struct PromptInputTests {

    @Test("resolve returns argument when provided")
    func resolveFromArgument() throws {
        let result = try PromptInput.resolve(argument: "Hello", filePath: nil)
        #expect(result == "Hello")
    }

    @Test("resolve reads from file when argument is nil")
    func resolveFromFile() throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("prompt-\(UUID().uuidString).txt")
        try "File content".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let result = try PromptInput.resolve(argument: nil, filePath: tempFile.path)
        #expect(result == "File content")
    }

    @Test("resolve prefers argument over file")
    func argumentOverFile() throws {
        let result = try PromptInput.resolve(argument: "From arg", filePath: "/nonexistent")
        #expect(result == "From arg")
    }

    @Test("resolve throws for nonexistent file")
    func nonexistentFile() {
        #expect(throws: AppError.self) {
            try PromptInput.resolve(argument: nil, filePath: "/nonexistent/file.txt")
        }
    }

    @Test("resolve throws when no input provided and stdin is a tty")
    func noInput() {
        // When running in tests, stdin is a tty, so this should throw
        #expect(throws: AppError.self) {
            try PromptInput.resolve(argument: nil, filePath: nil)
        }
    }

    @Test("resolve ignores empty argument")
    func emptyArgument() throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("prompt-\(UUID().uuidString).txt")
        try "Fallback".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let result = try PromptInput.resolve(argument: "", filePath: tempFile.path)
        #expect(result == "Fallback")
    }
}
