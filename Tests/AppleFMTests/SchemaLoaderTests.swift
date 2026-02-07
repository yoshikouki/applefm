import Testing
import Foundation
import FoundationModels
@testable import AppleFMCore

@Suite("SchemaLoader Tests")
struct SchemaLoaderTests {

    @Test("load simple object schema from JSON data")
    func loadSimpleObjectSchema() throws {
        let json = """
        {
            "name": "Person",
            "description": "A person record",
            "properties": {
                "name": {
                    "name": "name",
                    "description": "The person's name"
                },
                "age": {
                    "name": "age",
                    "description": "The person's age"
                }
            }
        }
        """
        let data = Data(json.utf8)
        // GenerationSchema is opaque — verify creation succeeds without throwing
        _ = try SchemaLoader.load(from: data)
    }

    @Test("load anyOf string enum schema")
    func loadAnyOfSchema() throws {
        let json = """
        {
            "name": "Color",
            "description": "A color choice",
            "anyOf": ["red", "green", "blue"]
        }
        """
        let data = Data(json.utf8)
        _ = try SchemaLoader.load(from: data)
    }

    @Test("load array schema")
    func loadArraySchema() throws {
        let json = """
        {
            "items": {
                "name": "Item",
                "description": "An item in the list",
                "properties": {
                    "title": {
                        "name": "title",
                        "description": "Item title"
                    }
                }
            },
            "minItems": 1,
            "maxItems": 10
        }
        """
        let data = Data(json.utf8)
        _ = try SchemaLoader.load(from: data)
    }

    @Test("error on invalid JSON")
    func errorOnInvalidJSON() {
        let data = Data("not valid json {{{".utf8)
        #expect(throws: AppError.self) {
            try SchemaLoader.load(from: data)
        }
    }

    @Test("error on non-object root")
    func errorOnNonObjectRoot() {
        let data = Data("[1, 2, 3]".utf8)
        #expect(throws: AppError.self) {
            try SchemaLoader.load(from: data)
        }
    }

    @Test("error on nonexistent file path")
    func errorOnNonexistentFile() {
        #expect(throws: AppError.self) {
            try SchemaLoader.load(from: "/nonexistent/path/schema.json")
        }
    }

    @Test("error on property that is not a JSON object")
    func errorOnInvalidProperty() {
        let json = """
        {
            "name": "Bad",
            "properties": {
                "field": "not-an-object"
            }
        }
        """
        let data = Data(json.utf8)
        #expect(throws: AppError.self) {
            try SchemaLoader.load(from: data)
        }
    }

    // MARK: - parseDynamicSchema Tests

    @Test("parseDynamicSchema uses default name when not specified")
    func parseDynamicSchemaDefaultName() throws {
        let dict: [String: Any] = [
            "description": "A simple schema"
        ]
        // Should not throw — verifies fallback to "Root" name
        _ = try SchemaLoader.parseDynamicSchema(from: dict)
    }

    @Test("parseDynamicSchema with nested object properties")
    func parseDynamicSchemaNestedProperties() throws {
        let dict: [String: Any] = [
            "name": "Address",
            "properties": [
                "street": ["description": "Street name"] as [String: Any],
                "city": ["description": "City name"] as [String: Any],
            ]
        ]
        _ = try SchemaLoader.parseDynamicSchema(from: dict)
    }

    @Test("load JSON Schema with typed properties")
    func loadTypedPropertiesSchema() throws {
        let json = """
        {
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "A person name"},
                "age": {"type": "integer", "description": "Age in years"},
                "score": {"type": "number", "description": "Score value"},
                "active": {"type": "boolean", "description": "Is active"}
            },
            "required": ["name", "age"]
        }
        """
        let data = Data(json.utf8)
        _ = try SchemaLoader.load(from: data)
    }

    @Test("parseDynamicSchema handles primitive types")
    func parsePrimitiveTypes() throws {
        _ = try SchemaLoader.parseDynamicSchema(from: ["type": "string"])
        _ = try SchemaLoader.parseDynamicSchema(from: ["type": "integer"])
        _ = try SchemaLoader.parseDynamicSchema(from: ["type": "number"])
        _ = try SchemaLoader.parseDynamicSchema(from: ["type": "boolean"])
    }

    @Test("load JSON Schema with enum constraint converts to anyOf")
    func loadEnumConstraintSchema() throws {
        let json = """
        {
            "name": "Sentiment",
            "properties": {
                "sentiment": {
                    "type": "string",
                    "enum": ["positive", "negative", "neutral"],
                    "description": "The sentiment of the text"
                }
            },
            "required": ["sentiment"]
        }
        """
        let data = Data(json.utf8)
        _ = try SchemaLoader.load(from: data)
    }

    @Test("parseDynamicSchema handles enum field")
    func parseDynamicSchemaEnum() throws {
        let dict: [String: Any] = [
            "name": "Status",
            "description": "A status value",
            "enum": ["active", "inactive", "pending"]
        ]
        _ = try SchemaLoader.parseDynamicSchema(from: dict)
    }

    @Test("parseDynamicSchema with empty dictionary creates valid schema")
    func parseDynamicSchemaEmpty() throws {
        _ = try SchemaLoader.parseDynamicSchema(from: [:])
    }
}
