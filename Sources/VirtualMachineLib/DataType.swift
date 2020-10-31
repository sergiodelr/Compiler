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
    case genType(identifier: Character)
    case errType
    case noneType
}
