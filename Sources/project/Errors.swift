//
// Created by sergio on 10/10/2020.
//

import Foundation
import VirtualMachineLib

public enum SemanticError: Error {
    case multipleDeclaration(symbol: String)
    case operatorTypeMismatch(op: LangOperator, left: DataType, right: DataType)
    case operatorTypeMismatchSingle(op: LangOperator, operand: DataType)
    case typeMismatch(expected: DataType, received: DataType)
    case symbolNotDeclared(symbol: String)
    case internalError
    case symbolAmbiguity(symbol: String)
    case genTypeNotSupported
    case invalidFuncCall
    case invalidArgCount(expected: Int, received: Int)
    case patternNotImplemented
    case invalidPatternCount(expected: Int, received: Int)
    case unassignedSymbol
    case impureCall

    func description() -> String {
        switch self {
        case let .typeMismatch(expected, received):
            return "Type mismatch. Expected: \(expected). Received: \(received)"
        case let .multipleDeclaration(symbol):
            return "Multiple declaration. Symbol: \(symbol)"
        case let .symbolNotDeclared(symbol):
            return "Symbol not declared. Symbol: \(symbol)"
        case .internalError:
            return "Internal semantic error."
        case let .symbolAmbiguity(symbol):
            return "Ambiguous symbol. Symbol: \(symbol)"
        case .genTypeNotSupported:
            return "Generic type is not yet supported."
        case .invalidFuncCall:
            return "Invalid function call."
        case let .invalidArgCount(expected, received):
            return "Invalid argument count. Expected: \(expected). Received: \(received)"
        case .patternNotImplemented:
            return "Pattern not implemented."
        case let .invalidPatternCount(expected, received):
            return "Invalid pattern count. Expected: \(expected). Received: \(received)"
        case let .operatorTypeMismatch(op, left, right):
            return "Invalid operand types for operator. Operator: \(op). Operands: \(left), \(right)"
        case let .operatorTypeMismatchSingle(op, operand):
            return "Invalid operand type for operator. Operator: \(op). Operand: \(operand)"
        case .unassignedSymbol:
            return "Unassigned symbol."
        case .impureCall:
            return "Impure call from pure scope."
        }
    }

    // Displays error message and stops execution. All semantic errors are considered fatal.
    public static func handle(_ err: SemanticError, line: Int? = nil, col: Int? = nil) {
        let errDescription = "Error at line: \(String(describing: line)), col: \(String(describing: col)). " +
                err.description()
        fatalError(errDescription)
    }
}
