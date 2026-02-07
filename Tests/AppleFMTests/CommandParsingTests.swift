import Testing
import ArgumentParser
@testable import AppleFMCore

@Suite("Command Parsing Tests")
struct CommandParsingTests {

    @Test("root command has correct command name")
    func rootCommandName() {
        #expect(AppleFM.configuration.commandName == "applefm")
    }

    @Test("root command default subcommand is respond")
    func defaultSubcommand() {
        #expect(AppleFM.configuration.defaultSubcommand == RespondCommand.self)
    }

    @Test("root command has expected subcommands")
    func subcommands() {
        let subcommandNames = AppleFM.configuration.subcommands.map { $0.configuration.commandName ?? "" }
        #expect(subcommandNames.contains("model"))
        #expect(subcommandNames.contains("session"))
        #expect(subcommandNames.contains("config"))
        #expect(subcommandNames.contains("respond"))
        #expect(subcommandNames.contains("generate"))
    }

    @Test("config command has expected subcommands")
    func configSubcommands() {
        let subcommandNames = ConfigCommand.configuration.subcommands.map { $0.configuration.commandName ?? "" }
        #expect(subcommandNames.contains("list"))
        #expect(subcommandNames.contains("get"))
        #expect(subcommandNames.contains("set"))
        #expect(subcommandNames.contains("reset"))
        #expect(subcommandNames.contains("describe"))
        #expect(subcommandNames.contains("init"))
        #expect(subcommandNames.contains("preset"))
    }

    @Test("version is set to 1.1.0")
    func versionString() {
        #expect(AppleFM.configuration.version == "1.1.0")
    }

    @Test("RespondCommand rejects --stream with --format json")
    func respondRejectsStreamJson() {
        var command = RespondCommand()
        command.stream = true
        command.format = .json
        #expect(throws: ValidationError.self) {
            try command.validate()
        }
    }

    @Test("RespondCommand allows --stream with --format text")
    func respondAllowsStreamText() throws {
        var command = RespondCommand()
        command.stream = true
        command.format = .text
        try command.validate()
    }

    @Test("RespondCommand allows --format json without --stream")
    func respondAllowsJsonNoStream() throws {
        var command = RespondCommand()
        command.stream = false
        command.format = .json
        try command.validate()
    }

    @Test("SessionRespondCommand rejects --stream with --format json")
    func sessionRespondRejectsStreamJson() {
        var command = SessionRespondCommand()
        command.name = "test"
        command.stream = true
        command.format = .json
        #expect(throws: ValidationError.self) {
            try command.validate()
        }
    }
}
