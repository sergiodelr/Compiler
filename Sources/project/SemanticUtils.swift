import Foundation
import VirtualMachineLib

// Operators supported in the language.
public enum LangOperator: String {
    case plusOp = "+"
    case minusOp = "-"
    case multOp = "*"
    case divOp = "/"
    case andOp = "&"
    case orOp = "|"
    case notOp = "!"
    case negOp
    case posOp
    case appendOp = "++"
    case consOp = ":"
    case eqOp = "=="
    case notEqOp = "!="
    case lThanOp = "<"
    case gThanOp = ">"
    case lEqOp = "<="
    case gEqOp = ">="
    case assgOp = "="

    case placeholderOp // Used to create a false bottom in the operator stack when parentheses are found in an exp.

    // Returns the operator's precedence level. A lower precedence number indicates higher precedence, starting at 0.
    public func precedence() -> Int {
        switch self {
        case .placeholderOp:
            return 0
        case .notOp, .negOp, .posOp:
            return 1
        case .consOp:
            return 2
        case .appendOp:
            return 3
        case .multOp, .divOp:
            return 4
        case .plusOp, .minusOp:
            return 5
        case .eqOp, .notEqOp, .lThanOp, .gThanOp, .lEqOp, .gEqOp:
            return 6
        case .andOp:
            return 7
        case .orOp:
            return 8
        case .assgOp:
            return 9
        }
    }
}

// Contains a static method to validate operand types with an operator.
public enum ExpressionTypeTable {
    // Table mapping [operator, type1, type2] to the operation's resulting type. The user shall use the default value
    // .errType when attempting to access the elements or expect a nil when an operation between data types is not
    // supported.
    private static let table: [LangOperator: [DataType: [DataType: DataType]]] = [
        // Plus operator.
        .plusOp: [
            .intType: [
                .intType: .intType,
                .floatType: .floatType
            ],
            .floatType: [
                .intType: .floatType,
                .floatType: .floatType
            ]
        ],
        // Minus operator.
        .minusOp: [
            .intType: [
                .intType: .intType,
                .floatType: .floatType
            ],
            .floatType: [
                .intType: .floatType,
                .floatType: .floatType
            ]
        ],
        // Multiplication operator.
        .multOp: [
            .intType: [
                .intType: .intType,
                .floatType: .floatType
            ],
            .floatType: [
                .intType: .floatType,
                .floatType: .floatType
            ]
        ],
        // Division operator.
        .divOp: [
            .intType: [
                .intType: .intType,
                .floatType: .floatType
            ],
            .floatType: [
                .intType: .floatType,
                .floatType: .floatType
            ]
        ],
        // Equal operator.
        .eqOp: [
            .intType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .floatType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .charType: [
                .charType: .boolType
            ],
            .boolType: [
                .boolType: .boolType
            ]
        ],
        // Not equal operator.
        .notEqOp: [
            .intType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .floatType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .charType: [
                .charType: .boolType
            ],
            .boolType: [
                .boolType: .boolType
            ]
        ],
        // Less than operator.
        .lThanOp: [
            .intType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .floatType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .charType: [
                .charType: .boolType
            ]
        ],
        // Greater than operator.
        .gThanOp: [
            .intType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .floatType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .charType: [
                .charType: .boolType
            ]
        ],
        // Less than or equal to operator.
        .lEqOp: [
            .intType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .floatType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .charType: [
                .charType: .boolType
            ]
        ],
        // Greater than or equal to operator.
        .gEqOp: [
            .intType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .floatType: [
                .intType: .boolType,
                .floatType: .boolType
            ],
            .charType: [
                .charType: .boolType
            ]
        ],
        // And operator.
        .andOp: [
            .boolType: [
                .boolType: .boolType
            ]
        ],
        // Or operator.
        .orOp: [
            .boolType: [
                .boolType: .boolType
            ]
        ]
    ]

    // Given an operator and the types of two operands, it returns the resulting data type.
    public static func getDataType(op: LangOperator, type1: DataType, type2: DataType) -> DataType {
        switch op {
        case .assgOp:
            if type1 == type2 {
                return type1
            } else if case DataType.intType = type1, case DataType.floatType = type2 {
                return type1
            } else if case DataType.floatType = type1, case DataType.intType = type2 {
                return type1
            } else if case let DataType.listType(innerType1) = type1,
                      case let DataType.listType(innerType2) = type2 {
                if innerType1 == innerType2 || innerType2 == .noneType || canCast(to: innerType1, from: innerType2) {
                    return type1
                }
            }
        case .consOp:
            if case let DataType.listType(innerType) = type2, type1 == innerType {
                return .listType(innerType: type1)
            } else if case let DataType.listType(innerType) = type2, innerType == .noneType {
                return .listType(innerType: type1)
            }
        case .appendOp:
            if case let DataType.listType(innerType1) = type1,
               case let DataType.listType(innerType2) = type2 {
                if innerType1 == innerType2 || innerType2 == .noneType {
                    return .listType(innerType: innerType1)
                } else if innerType1 == .noneType {
                    return .listType(innerType: innerType2)
                }
            }
        case .notOp:
            if case DataType.boolType = type1 {
                return .boolType
            }
        case .posOp:
            if case DataType.intType = type1 {
                return .intType
            } else if case DataType.floatType = type1 {
                return .floatType
            } else if case let DataType.listType(innerType) = type1 {
                return .listType(innerType: innerType)
            }
        case .negOp:
            if case DataType.intType = type1 {
                return .intType
            } else if case DataType.floatType = type1 {
                return .floatType
            } else if case let DataType.listType(innerType) = type1 {
                return innerType
            }
        case .eqOp, .notEqOp:
            if case let DataType.listType(innerType1) = type1,
               case let DataType.listType(innerType2) = type2 {
                if canCast(to: innerType1, from: innerType2) || canCast(to: innerType2, from: innerType1) {
                    return .boolType
                } else if innerType1 == .noneType || innerType2 == .noneType {
                    return .boolType
                }
            }
            fallthrough // If the types are other than lists, they must be checked in the table.
        default:
            return table[op]?[type1]?[type2] ?? .errType
        }
        return .errType
    }

    // Checks whether two data types are compatible for casting.
    public static func canCast(to type1: DataType, from type2: DataType) -> Bool {
        if case let DataType.listType(innerType1) = type1,
           case let DataType.listType(innerType2) = type2,
           innerType1 != innerType2 && innerType1 != .noneType && innerType2 != .noneType {
            return false
        }
        return getDataType(op: .assgOp, type1: type1, type2: type2) != .errType
    }

    // Returns the most inner type of the given list type.
    public static func mostInnerType(ofListType type: DataType) -> DataType {
        if case let DataType.listType(innerType) = type {
            return mostInnerType(ofListType: innerType)
        }
        return type
    }
}

