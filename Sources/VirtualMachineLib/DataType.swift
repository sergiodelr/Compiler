//
// Created by sergio on 30/10/2020.
//

import Foundation

// A data type. Includes function and list types, which contain recursive associated values. The generic type contains
// the given identifier.
public enum DataType: Hashable {
    case intType
    case boolType
    case floatType
    case charType
    indirect case listType(innerType: DataType)
    indirect case funcType(paramTypes: [DataType], returnType: DataType)
    case genType(identifier: String)
    case errType
    case noneType
}

extension DataType: Codable {

    enum Key: CodingKey {
        case intType
        case boolType
        case floatType
        case charType
        case listType
        case funcType
        case genType
        case errType
        case noneType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let key = container.allKeys.first!

        switch key {
        case .intType:
            self = .intType
        case .boolType:
            self = .boolType
        case .floatType:
            self = .floatType
        case .charType:
            self = .charType
        case .listType:
            let innerType = try container.decode(DataType.self, forKey: .listType)
            self = .listType(innerType: innerType)
        case .funcType:
            let (paramTypes, returnType): ([DataType], DataType) = try container.decodeValues(for: .funcType)
            self = .funcType(paramTypes: paramTypes, returnType: returnType)
        case .genType:
            let identifier = try container.decode(String.self, forKey: .genType)
            self = .genType(identifier: identifier)
        case .errType:
            self = .errType
        case .noneType:
            self = .noneType
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)

        switch self {
        case .intType:
            try container.encode(true, forKey: .intType)
        case .boolType:
            try container.encode(true, forKey: .boolType)
        case .floatType:
            try container.encode(true, forKey: .floatType)
        case .charType:
            try container.encode(true, forKey: .charType)
        case .listType(let innerType):
            try container.encode(innerType, forKey: .listType)
        case let .funcType(paramTypes, returnType):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .funcType)
            try nestedContainer.encode(paramTypes)
            try nestedContainer.encode(returnType)
        case .genType(let identifier):
            try container.encode(identifier, forKey: .genType)
        case .errType:
            try container.encode(true, forKey: .errType)
        case .noneType:
            try container.encode(true, forKey: .noneType)
        }
    }
}

extension KeyedEncodingContainer {
    mutating func encodeValues<V1: Encodable, V2: Encodable>(_ v1: V1, _ v2: V2, for key: Key) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
    }
}

extension KeyedDecodingContainer {
    func decodeValues<V1: Decodable, V2: Decodable>(for key: Key) throws -> (V1, V2) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
                try container.decode(V1.self),
                try container.decode(V2.self)
        )
    }
}