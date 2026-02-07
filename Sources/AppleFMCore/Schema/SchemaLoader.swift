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
        let type = dict["type"] as? String

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

        // array (via "items" key or "type": "array")
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
            let required = dict["required"] as? [String] ?? []
            let properties = try props.sorted(by: { $0.key < $1.key }).map { key, value in
                guard let propDict = value as? [String: Any] else {
                    throw AppError.invalidInput("Property '\(key)' must be a JSON object")
                }
                let propDescription = propDict["description"] as? String
                let propSchema = try parseDynamicSchema(from: propDict.merging(["name": key]) { existing, _ in existing })
                let isOptional = !required.contains(key)
                return DynamicGenerationSchema.Property(name: key, description: propDescription, schema: propSchema, isOptional: isOptional)
            }
            return DynamicGenerationSchema(name: name, description: description, properties: properties)
        }

        // Primitive types (JSON Schema "type" field)
        if let type {
            switch type {
            case "string":
                return DynamicGenerationSchema(type: String.self)
            case "integer":
                return DynamicGenerationSchema(type: Int.self)
            case "number":
                return DynamicGenerationSchema(type: Double.self)
            case "boolean":
                return DynamicGenerationSchema(type: Bool.self)
            default:
                break
            }
        }

        // Leaf node with just name/description (no type specified)
        return DynamicGenerationSchema(name: name, description: description, properties: [])
    }
}
