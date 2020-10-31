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
    // TODO: update counts.
    public let paramCount: Int = 0
    public let tempCount: Int = 0
    public let constCount: Int = 0

    public init(address: Int, value: Int) {
        self.address = address
        self.value = value
    }
}