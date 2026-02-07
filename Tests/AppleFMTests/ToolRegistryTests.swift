import Testing
@testable import AppleFMCore

@Suite("ToolRegistry Tests")
struct ToolRegistryTests {

    @Test("allToolNames contains expected values")
    func allToolNamesContainsExpectedValues() {
        #expect(ToolRegistry.allToolNames.contains("shell"))
        #expect(ToolRegistry.allToolNames.contains("file-read"))
        #expect(ToolRegistry.allToolNames.count == 2)
    }

    @Test("resolve with empty names returns empty array")
    func resolveEmptyNames() throws {
        let tools = try ToolRegistry.resolve(names: [])
        #expect(tools.isEmpty)
    }

    @Test("resolve with shell returns array with 1 tool")
    func resolveSingleShellTool() throws {
        let tools = try ToolRegistry.resolve(names: ["shell"])
        #expect(tools.count == 1)
    }

    @Test("resolve with shell and file-read returns array with 2 tools")
    func resolveMultipleTools() throws {
        let tools = try ToolRegistry.resolve(names: ["shell", "file-read"])
        #expect(tools.count == 2)
    }

    @Test("resolve accepts file_read underscore variant")
    func resolveFileReadUnderscoreVariant() throws {
        let tools = try ToolRegistry.resolve(names: ["file_read"])
        #expect(tools.count == 1)
    }

    @Test("resolve throws AppError for unknown tool name")
    func resolveUnknownToolThrows() {
        #expect(throws: AppError.self) {
            try ToolRegistry.resolve(names: ["unknown"])
        }
    }

    @Test("resolve with custom approval passes through")
    func resolveWithCustomApproval() throws {
        let approval = ToolApproval(mode: .auto)
        let tools = try ToolRegistry.resolve(names: ["shell"], approval: approval)
        #expect(tools.count == 1)
    }
}
