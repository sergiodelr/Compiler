//
// Created by sergio on 10/10/2020.
//

import Foundation

public enum SemanticError: Error {
    case multipleDeclaration(symbol: String)
    case typeMismatch(expected: DataType, received: DataType)
    case internalError

    func description() -> String {
        switch self {
        case let .typeMismatch(expected, received):
            return "Type mismatch. Expected: \(expected). Received: \(received)"
        case let .multipleDeclaration(symbol):
            return "Multiple declaration. Symbol: \(symbol)"
        case .internalError:
            return "Internal semantic error."
        }
    }

    // Displays error message and stops execution. All semantic errors are considered fatal.
    public static func handle(_ err: SemanticError, line: Int, col: Int) {
        let errDescription = "Error at line: \(line), col: \(col). " + err.description()
        fatalError(errDescription)
    }
}
