import Testing
import Foundation
@testable import AppleFMCore

@Suite("ToolApproval Tests")
struct ToolApprovalTests {

    // MARK: - Auto Mode

    @Test("auto mode always approves")
    func autoModeApproves() {
        let approval = ToolApproval(mode: .auto)
        #expect(approval.requestApproval(toolName: "shell", description: "ls -la"))
    }

    // MARK: - Ask Mode (interactive)

    @Test("ask mode approves on 'y'")
    func askModeApprovesY() {
        nonisolated(unsafe) var stderrOutput = ""
        let approval = ToolApproval(
            mode: .ask,
            isInteractive: { true },
            readInput: { "y" },
            writeStderr: { stderrOutput += $0 }
        )
        #expect(approval.requestApproval(toolName: "shell", description: "echo hello"))
        #expect(stderrOutput.contains("shell"))
        #expect(stderrOutput.contains("echo hello"))
        #expect(stderrOutput.contains("Allow?"))
    }

    @Test("ask mode approves on 'yes'")
    func askModeApprovesYes() {
        let approval = ToolApproval(
            mode: .ask,
            isInteractive: { true },
            readInput: { "yes" },
            writeStderr: { _ in }
        )
        #expect(approval.requestApproval(toolName: "shell", description: "test"))
    }

    @Test("ask mode denies on 'n'")
    func askModeDeniesN() {
        let approval = ToolApproval(
            mode: .ask,
            isInteractive: { true },
            readInput: { "n" },
            writeStderr: { _ in }
        )
        #expect(!approval.requestApproval(toolName: "shell", description: "rm -rf /"))
    }

    @Test("ask mode denies on empty input")
    func askModeDeniesEmpty() {
        let approval = ToolApproval(
            mode: .ask,
            isInteractive: { true },
            readInput: { "" },
            writeStderr: { _ in }
        )
        #expect(!approval.requestApproval(toolName: "shell", description: "test"))
    }

    @Test("ask mode denies on nil (EOF)")
    func askModeDeniesNil() {
        let approval = ToolApproval(
            mode: .ask,
            isInteractive: { true },
            readInput: { nil },
            writeStderr: { _ in }
        )
        #expect(!approval.requestApproval(toolName: "shell", description: "test"))
    }

    // MARK: - Non-interactive

    @Test("ask mode denies in non-interactive environment with stderr message")
    func askModeDeniesNonInteractive() {
        nonisolated(unsafe) var stderrOutput = ""
        let approval = ToolApproval(
            mode: .ask,
            isInteractive: { false },
            readInput: { "y" },
            writeStderr: { stderrOutput += $0 }
        )
        #expect(!approval.requestApproval(toolName: "shell", description: "ls"))
        #expect(stderrOutput.contains("requires approval"))
        #expect(stderrOutput.contains("--tool-approval auto"))
    }
}
