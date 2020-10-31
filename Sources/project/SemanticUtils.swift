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
        case .appendOp, .consOp:
            return 2
        case .multOp, .divOp:
            return 3
        case .plusOp, .minusOp:
            return 4
        case .eqOp, .notEqOp, .lThanOp, .gThanOp, .lEqOp, .gEqOp:
            return 5
        case .andOp:
            return 6
        case .orOp:
            return 7
        case .assgOp:
            return 8
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
            }
        case .consOp:
            if case let DataType.listType(innerType) = type2, type1 == innerType {
                return .listType(innerType: type1)
            }
        case .appendOp:
            if case let DataType.listType(innerType1) = type1,
               case let DataType.listType(innerType2) = type2,
               innerType1 == innerType2 {
                return .listType(innerType: type1)
            }
        case .notOp:
            if case DataType.boolType = type1 {
                return .boolType
            }
        case .posOp, .negOp:
            if case DataType.intType = type1 {
                return .intType
            } else if case DataType.floatType = type1 {
                return .floatType
            }
        default:
            return table[op]?[type1]?[type2] ?? .errType
        }
        return .errType
    }
}

