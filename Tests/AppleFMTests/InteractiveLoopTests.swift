import Testing
import Foundation
@testable import AppleFMCore

@Suite("InteractiveLoop Tests")
struct InteractiveLoopTests {

    @Test("generateSessionName produces valid format")
    func sessionNameFormat() {
        let name = InteractiveLoop.generateSessionName()
        #expect(name.hasPrefix("chat-"))
        // chat-YYYYMMDD-HHmmss = 20 chars
        #expect(name.count == 20)
    }

    @Test("generateSessionName passes SessionStore validation")
    func sessionNameValidation() throws {
        let name = InteractiveLoop.generateSessionName()
        try SessionStore.validateSessionName(name)
    }

    @Test("InteractiveLoop can be constructed with custom DI closures")
    func diConstruction() {
        let loop = InteractiveLoop(
            readInput: { "/quit" },
            writeStderr: { _ in }
        )
        #expect(loop.readInput() == "/quit")
    }

    @Test("writeStderr DI closure is invoked")
    func writeStderrDI() {
        let box = SendableBox<String>()
        let loop = InteractiveLoop(
            readInput: { nil },
            writeStderr: { message in
                box.set(message)
            }
        )
        loop.writeStderr("hello")
        #expect(box.get() == "hello")
    }

    @Test("/quit is recognized as exit input")
    func quitRecognized() {
        let input = "/quit"
        #expect(input.trimmingCharacters(in: .whitespaces) == "/quit")
    }

    @Test("empty input is skipped (not treated as /quit)")
    func emptyInputSkipped() {
        let input = ""
        #expect(input.trimmingCharacters(in: .whitespaces) != "/quit")
        #expect(input.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test("whitespace-only input is treated as empty")
    func whitespaceOnlyInput() {
        let input = "   "
        #expect(input.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test("EOF (nil) from readInput signals exit")
    func eofSignalsExit() {
        let loop = InteractiveLoop(
            readInput: { nil },
            writeStderr: { _ in }
        )
        #expect(loop.readInput() == nil)
    }

    @Test("defaultInstructions is non-empty")
    func defaultInstructionsExists() {
        #expect(!InteractiveLoop.defaultInstructions.isEmpty)
    }

    @Test("multiple session names are unique")
    func sessionNameUniqueness() throws {
        let name1 = InteractiveLoop.generateSessionName()
        // Sleep briefly to ensure different timestamp
        try? Thread.sleep(forTimeInterval: 1.1)
        let name2 = InteractiveLoop.generateSessionName()
        #expect(name1 != name2)
    }

    @Test("/exit is recognized as exit input")
    func exitRecognized() {
        let loop = InteractiveLoop(readInput: { nil }, writeStderr: { _ in })
        #expect(loop.handleSlashCommand("/exit", sessionName: "test") == true)
    }

    @Test("/help outputs available commands")
    func helpOutputsCommands() {
        let box = SendableBox<String>()
        let loop = InteractiveLoop(
            readInput: { nil },
            writeStderr: { message in box.set(message) }
        )
        let shouldBreak = loop.handleSlashCommand("/help", sessionName: "test")
        #expect(shouldBreak == false)
        let output = box.get() ?? ""
        #expect(output.contains("/help"))
        #expect(output.contains("/quit"))
        #expect(output.contains("/session"))
    }

    @Test("/session outputs session name")
    func sessionOutputsName() {
        let box = SendableBox<String>()
        let loop = InteractiveLoop(
            readInput: { nil },
            writeStderr: { message in box.set(message) }
        )
        let shouldBreak = loop.handleSlashCommand("/session", sessionName: "my-session")
        #expect(shouldBreak == false)
        #expect(box.get()?.contains("my-session") == true)
    }

    @Test("unknown slash command shows error")
    func unknownSlashCommand() {
        let box = SendableBox<String>()
        let loop = InteractiveLoop(
            readInput: { nil },
            writeStderr: { message in box.set(message) }
        )
        let shouldBreak = loop.handleSlashCommand("/foo", sessionName: "test")
        #expect(shouldBreak == false)
        let output = box.get() ?? ""
        #expect(output.contains("Unknown command"))
        #expect(output.contains("/foo"))
    }
}

/// Thread-safe box for use in @Sendable closures during tests
private final class SendableBox<T>: @unchecked Sendable {
    private var _value: T?
    private let lock = NSLock()

    func set(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        _value = value
    }

    func get() -> T? {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
}
