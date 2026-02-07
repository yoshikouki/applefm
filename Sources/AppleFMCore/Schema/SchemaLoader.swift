import Foundation
import FoundationModels

/// JSON ファイルから DynamicGenerationSchema を構築し GenerationSchema に変換する
public struct SchemaLoader: Sendable {

    /// JSON ファイルパスからスキーマを読み込む
    public static func load(from path: String) throws -> GenerationSchema {
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw AppError.fileError("Cannot read schema file: \(path)")
        }
        return try load(from: data)
    }

    /// JSON データからスキーマを読み込む
    public static func load(from data: Data) throws -> GenerationSchema {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw AppError.invalidInput("Invalid JSON in schema file: \(error.localizedDescription)")
        }

        guard let root = json as? [String: Any] else {
            throw AppError.invalidInput("Schema root must be a JSON object")
        }

        let dynamicSchema = try parseDynamicSchema(from: root)
        return try GenerationSchema(root: dynamicSchema, dependencies: [])
    }

    // MARK: - Private

    static func parseDynamicSchema(from dict: [String: Any]) throws -> DynamicGenerationSchema {
        let name = dict["name"] as? String ?? "Root"
        let description = dict["description"] as? String

        // anyOf (string enum)
        if let anyOf = dict["anyOf"] as? [String] {
            return DynamicGenerationSchema(
                name: name,
                description: description,
                anyOf: anyOf.map { choice in
                    DynamicGenerationSchema(name: choice, description: nil, anyOf: [choice])
                }
            )
        }

        // array
        if let items = dict["items"] as? [String: Any] {
            let itemSchema = try parseDynamicSchema(from: items)
            let minElements = dict["minItems"] as? Int
            let maxElements = dict["maxItems"] as? Int
            return DynamicGenerationSchema(
                arrayOf: itemSchema,
                minimumElements: minElements,
                maximumElements: maxElements
            )
        }

        // object with properties
        if let props = dict["properties"] as? [String: Any] {
            let properties = try props.sorted(by: { $0.key < $1.key }).map { key, value in
                guard let propDict = value as? [String: Any] else {
                    throw AppError.invalidInput("Property '\(key)' must be a JSON object")
                }
                var propSchema = try parseDynamicSchema(from: propDict)
                // Use property key as name if not specified
                if propDict["name"] == nil {
                    propSchema = try parseDynamicSchema(from: propDict.merging(["name": key]) { _, new in new })
                }
                return DynamicGenerationSchema.Property(name: key, schema: propSchema)
            }
            return DynamicGenerationSchema(name: name, description: description, properties: properties)
        }

        // Simple type (leaf node with just name/description)
        return DynamicGenerationSchema(name: name, description: description, properties: [])
    }
}
