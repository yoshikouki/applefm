import Testing
@testable import AppleFMCore

@Suite("AppError Tests")
struct AppErrorTests {

    // MARK: - Message Tests

    @Test("modelNotAvailable message includes reason")
    func modelNotAvailableMessage() {
        let error = AppError.modelNotAvailable("Device not eligible")
        #expect(error.message.contains("Foundation Models is not available"))
        #expect(error.message.contains("Device not eligible"))
    }

    @Test("sessionNotFound message includes session name")
    func sessionNotFoundMessage() {
        let error = AppError.sessionNotFound("my-session")
        #expect(error.message.contains("Session not found"))
        #expect(error.message.contains("my-session"))
    }

    @Test("invalidInput message includes detail")
    func invalidInputMessage() {
        let error = AppError.invalidInput("Missing argument")
        #expect(error.message.contains("Invalid input"))
        #expect(error.message.contains("Missing argument"))
    }

    @Test("fileError message includes detail")
    func fileErrorMessage() {
        let error = AppError.fileError("Cannot read file")
        #expect(error.message.contains("File error"))
        #expect(error.message.contains("Cannot read file"))
    }

    @Test("generationError wraps underlying error")
    func generationErrorMessage() {
        struct TestError: Error, CustomStringConvertible {
            let description = "test failure"
        }
        let error = AppError.generationError(TestError())
        #expect(error.message.contains("Error:"))
    }

    // MARK: - Exit Code Tests

    @Test("modelNotAvailable exit code is 10")
    func modelNotAvailableExitCode() {
        let error = AppError.modelNotAvailable("test")
        #expect(error.exitCode == 10)
    }

    @Test("sessionNotFound exit code is 1")
    func sessionNotFoundExitCode() {
        let error = AppError.sessionNotFound("test")
        #expect(error.exitCode == 1)
    }

    @Test("invalidInput exit code is 1")
    func invalidInputExitCode() {
        let error = AppError.invalidInput("test")
        #expect(error.exitCode == 1)
    }

    @Test("fileError exit code is 1")
    func fileErrorExitCode() {
        let error = AppError.fileError("test")
        #expect(error.exitCode == 1)
    }

    @Test("generationError with non-GenerationError has exit code 1")
    func generationErrorGenericExitCode() {
        struct TestError: Error {}
        let error = AppError.generationError(TestError())
        #expect(error.exitCode == 1)
    }

    // MARK: - errorDescription consistency

    @Test("errorDescription equals message for all cases")
    func errorDescriptionConsistency() {
        let cases: [AppError] = [
            .modelNotAvailable("reason"),
            .sessionNotFound("name"),
            .invalidInput("detail"),
            .fileError("detail"),
        ]
        for error in cases {
            #expect(error.errorDescription == error.message)
        }
    }
}
