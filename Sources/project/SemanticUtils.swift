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

    case placeholderOp // Used to create a false bottom in the operator stack when parentheses are found in an exp.

    // Returns the operator's precedence level. A lower precedence number indicates higher precedence, starting at 0.
    public func precedence() -> Int {
        switch self {
        case .notOp, .negOp, .posOp, .placeholderOp:
            return 0
        case .appendOp, .consOp:
            return 1
        case .multOp, .divOp:
            return 2
        case .plusOp, .minusOp:
            return 3
        case .eqOp, .notEqOp, .lThanOp, .gThanOp, .lEqOp, .gEqOp:
            return 4
        case .andOp:
            return 5
        case .orOp:
            return 6
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
        .andOp: [
            .boolType: [
                .boolType: .boolType
            ]
        ],
        .orOp: [
            .boolType: [
                .boolType: .boolType
            ]
        ]
    ]

    // Given an operator and the types of two operands, it returns the resulting data type.
    public static func getDataType(op: LangOperator, type1: DataType, type2: DataType) -> DataType {
        switch op {
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
        default:
            return table[op]?[type1]?[type2] ?? .errType
        }
        return .errType
    }
}

