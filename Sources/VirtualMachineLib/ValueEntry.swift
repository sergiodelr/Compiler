//
// Created by sergio on 30/10/2020.
//

import Foundation

public protocol ValueEntry {
    var address: Int { get }
    var value: Any? { get }
    var type: DataType { get }
}

public struct LiteralValueEntry: ValueEntry {
    public let address: Int
    public let value: Any?
    public let type: DataType

    public init(address: Int, value: Any, type: DataType) {
        self.address = address
        self.value = value
        self.type = type
    }
}

public struct FuncValueEntry: ValueEntry {
    public let address: Int
    // The instruction pointer to the beginning of the function. Type Int
    public let value: Any?
    public var type: DataType { return .funcType(paramTypes: [], returnType: .noneType) }
    public let paramTypes: [DataType]
    public let returnType: DataType
    public var paramCount: Int { return paramTypes.count }
    // Address counts for each data type.
    public var tempCount = [DataType: Int]()
    public var constCount = [DataType: Int]()
    // Symbols in the context. This is set at runtime.
    public var context = [ValueEntry]()

    public init(address: Int, value: Int, type: DataType) {
        self.address = address
        self.value = value
        // Condition will always be true.
        if case let DataType.funcType(paramTypes , returnType) = type{
            self.paramTypes = paramTypes
            self.returnType = returnType
        } else {
            self.paramTypes = []
            self.returnType = .noneType
        }

    }
}

public struct ListValueEntry: ValueEntry {
    public let address: Int
    // An address of the contained value.
    public let value: Any?
    public var type: DataType {
        return .listType(innerType: .noneType)
    }
    // The next value's address.
    public var next: Int? = nil
    public var innerType = DataType.noneType

    public init(address: Int, value: Any?) {
        self.address = address
        self.value = value
    }
}