import Foundation
import FoundationModels

/// Transcript エントリをフォーマットして出力する
public struct TranscriptFormatter: Sendable {
    public let format: OutputFormat

    public init(format: OutputFormat = .text) {
        self.format = format
    }

    /// Transcript 全体をフォーマット
    public func formatTranscript(_ transcript: Transcript) -> String {
        switch format {
        case .text:
            return formatTranscriptAsText(transcript)
        case .json:
            return formatTranscriptAsJSON(transcript)
        }
    }

    // MARK: - Text Format

    private func formatTranscriptAsText(_ transcript: Transcript) -> String {
        var lines: [String] = []
        for entry in transcript {
            lines.append(formatEntry(entry))
        }
        return lines.joined(separator: "\n\n")
    }

    private func formatEntry(_ entry: Transcript.Entry) -> String {
        switch entry {
        case .instructions(let instructions):
            let text = segmentsToText(instructions.segments)
            return "[instructions]\n\(text)"
        case .prompt(let prompt):
            let text = segmentsToText(prompt.segments)
            return "[prompt]\n\(text)"
        case .response(let response):
            let text = segmentsToText(response.segments)
            return "[response]\n\(text)"
        case .toolCalls(let toolCalls):
            let calls = toolCalls.map { call in
                "\(call.toolName)(\(call.arguments))"
            }.joined(separator: ", ")
            return "[tool_calls]\n\(calls)"
        case .toolOutput(let toolOutput):
            let text = segmentsToText(toolOutput.segments)
            return "[tool_output]\n\(text)"
        @unknown default:
            return "[unknown]"
        }
    }

    private func segmentsToText(_ segments: [Transcript.Segment]) -> String {
        segments.map { segment in
            switch segment {
            case .text(let textSegment):
                return textSegment.content
            case .structure(let structuredSegment):
                return structuredSegment.source
            @unknown default:
                return ""
            }
        }.joined()
    }

    // MARK: - JSON Format

    private func formatTranscriptAsJSON(_ transcript: Transcript) -> String {
        let entries: [[String: Any]] = transcript.map { entry -> [String: Any] in
            switch entry {
            case .instructions(let instructions):
                return [
                    "type": "instructions",
                    "content": segmentsToText(instructions.segments),
                ]
            case .prompt(let prompt):
                return [
                    "type": "prompt",
                    "content": segmentsToText(prompt.segments),
                ]
            case .response(let response):
                return [
                    "type": "response",
                    "content": segmentsToText(response.segments),
                ]
            case .toolCalls(let toolCalls):
                return [
                    "type": "tool_calls",
                    "calls": toolCalls.map { [
                        "name": $0.toolName,
                        "arguments": $0.arguments,
                    ] },
                ]
            case .toolOutput(let toolOutput):
                return [
                    "type": "tool_output",
                    "content": segmentsToText(toolOutput.segments),
                ]
            @unknown default:
                return ["type": "unknown"]
            }
        }

        guard let data = try? JSONSerialization.data(
            withJSONObject: entries,
            options: [.prettyPrinted, .sortedKeys]
        ),
            let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return string
    }
}
