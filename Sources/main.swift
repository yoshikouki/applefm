import Foundation
import FoundationModels

let model = SystemLanguageModel.default
guard model.isAvailable else {
    print("Error: Foundation Models is not available on this device.")
    Darwin.exit(1)
}

let session = LanguageModelSession()
let response = try await session.respond(to: "Hello! What can you do?")
print(response.content)
