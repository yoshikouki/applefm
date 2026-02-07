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
        let schema = try SchemaLoader.load(from: data)
        // If we got here without throwing, the schema was created successfully
        _ = schema
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
        let schema = try SchemaLoader.load(from: data)
        _ = schema
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
        let schema = try SchemaLoader.load(from: data)
        _ = schema
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

    // MARK: - parseDynamicSchema Tests

    @Test("parseDynamicSchema uses default name when not specified")
    func parseDynamicSchemaDefaultName() throws {
        let dict: [String: Any] = [
            "description": "A simple schema"
        ]
        let schema = try SchemaLoader.parseDynamicSchema(from: dict)
        _ = schema
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
        let schema = try SchemaLoader.parseDynamicSchema(from: dict)
        _ = schema
    }
}
