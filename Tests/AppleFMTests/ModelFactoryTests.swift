import Testing
import FoundationModels
@testable import AppleFMCore

@Suite("ModelFactory Tests")
struct ModelFactoryTests {

    // MARK: - GuardrailsOption

    @Test("GuardrailsOption default has correct raw value")
    func guardrailsDefaultRawValue() {
        #expect(GuardrailsOption.default.rawValue == "default")
    }

    @Test("GuardrailsOption permissive has correct raw value")
    func guardrailsPermissiveRawValue() {
        #expect(GuardrailsOption.permissive.rawValue == "permissive")
    }

    @Test("GuardrailsOption allCases has 2 cases")
    func guardrailsAllCasesCount() {
        #expect(GuardrailsOption.allCases.count == 2)
    }

    // MARK: - makeGenerationOptions

    @Test("makeGenerationOptions with no args returns default options")
    func makeGenerationOptionsDefaults() {
        let options = ModelFactory.makeGenerationOptions()
        // Default options should have nil for maximumResponseTokens and temperature
        #expect(options.maximumResponseTokens == nil)
        #expect(options.temperature == nil)
    }

    @Test("makeGenerationOptions with maxTokens sets maximumResponseTokens")
    func makeGenerationOptionsMaxTokens() {
        let options = ModelFactory.makeGenerationOptions(maxTokens: 100)
        #expect(options.maximumResponseTokens == 100)
        #expect(options.temperature == nil)
    }

    @Test("makeGenerationOptions with temperature sets temperature")
    func makeGenerationOptionsTemperature() {
        let options = ModelFactory.makeGenerationOptions(temperature: 0.5)
        #expect(options.maximumResponseTokens == nil)
        #expect(options.temperature == 0.5)
    }

    @Test("makeGenerationOptions with both maxTokens and temperature sets both")
    func makeGenerationOptionsBoth() {
        let options = ModelFactory.makeGenerationOptions(maxTokens: 100, temperature: 0.5)
        #expect(options.maximumResponseTokens == 100)
        #expect(options.temperature == 0.5)
    }
}
