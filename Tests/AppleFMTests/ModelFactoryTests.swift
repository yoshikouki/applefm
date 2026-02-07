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

    @Test("makeGenerationOptions with sampling sets sampling")
    func makeGenerationOptionsWithSampling() {
        let options = ModelFactory.makeGenerationOptions(sampling: .greedy)
        #expect(options.sampling != nil)
    }

    @Test("makeGenerationOptions with all parameters sets all")
    func makeGenerationOptionsAll() {
        let options = ModelFactory.makeGenerationOptions(maxTokens: 200, temperature: 0.8, sampling: .greedy)
        #expect(options.maximumResponseTokens == 200)
        #expect(options.temperature == 0.8)
        #expect(options.sampling != nil)
    }

    // MARK: - SamplingModeOption

    @Test("SamplingModeOption greedy has correct raw value")
    func samplingModeGreedyRawValue() {
        #expect(SamplingModeOption.greedy.rawValue == "greedy")
    }

    @Test("SamplingModeOption allCases has 1 case")
    func samplingModeAllCasesCount() {
        #expect(SamplingModeOption.allCases.count == 1)
    }

    // MARK: - resolveSamplingMode

    @Test("resolveSamplingMode with no args returns nil")
    func resolveSamplingModeNone() {
        let result = ModelFactory.resolveSamplingMode()
        #expect(result == nil)
    }

    @Test("resolveSamplingMode with greedy returns greedy")
    func resolveSamplingModeGreedy() {
        let result = ModelFactory.resolveSamplingMode(mode: .greedy)
        #expect(result != nil)
    }

    @Test("resolveSamplingMode with threshold returns random mode")
    func resolveSamplingModeThreshold() {
        let result = ModelFactory.resolveSamplingMode(threshold: 0.9)
        #expect(result != nil)
    }

    @Test("resolveSamplingMode with top returns random mode")
    func resolveSamplingModeTop() {
        let result = ModelFactory.resolveSamplingMode(top: 10)
        #expect(result != nil)
    }

    @Test("resolveSamplingMode with threshold and seed returns random mode")
    func resolveSamplingModeThresholdWithSeed() {
        let result = ModelFactory.resolveSamplingMode(threshold: 0.9, seed: 42)
        #expect(result != nil)
    }

    @Test("resolveSamplingMode with top and seed returns random mode")
    func resolveSamplingModeTopWithSeed() {
        let result = ModelFactory.resolveSamplingMode(top: 10, seed: 42)
        #expect(result != nil)
    }

    @Test("resolveSamplingMode greedy takes priority over threshold")
    func resolveSamplingModeGreedyPriority() {
        // When both greedy and threshold are specified, greedy wins
        let result = ModelFactory.resolveSamplingMode(mode: .greedy, threshold: 0.9)
        #expect(result != nil)
    }
}
