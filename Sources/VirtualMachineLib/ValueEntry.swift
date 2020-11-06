//
// Created by sergio on 30/10/2020.
//

import Foundation

public protocol ValueEntry {
    var address: Int { get }
    var value: Any { get }
    var type: DataType { get }
}

public struct LiteralValueEntry: ValueEntry {
    public let address: Int
    public let value: Any
    public let type: DataType

    public init(address: Int, value: Any, type: DataType) {
        self.address = address
        self.value = value
        self.type = type
    }
}

public struct FuncValueEntry: ValueEntry {
    public let address: Int
    public let value: Any
    public var type: DataType { return .funcType(paramTypes: [], returnType: .noneType) }
    public let paramTypes: [DataType]
    public let returnType: DataType
    // TODO: update counts.
    public var paramCount: Int { return paramTypes.count }
    public var tempCount: Int = 0
    public var constCount: Int = 0
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