//
// Created by sergio on 22/11/2020.
//

import Foundation

enum ExecutionError: Error {
    case corruptedList
    case emptyList
    case listNotComparable
    case notSupported
    case valueError
    case readError
    case typeError

    func description() -> String {
        switch self {
        case .corruptedList:
            return "Corrupted list."
        case .emptyList:
            return "Empty list."
        case .listNotComparable:
            return "Lists are not comparable."
        case .notSupported:
            return "Functionality currently not supported."
        case .valueError:
            return "Value error."
        case .readError:
            return "Read error."
        case .typeError:
            return "Type error."
        }
    }

    static func handle(_ error: ExecutionError) {
        fatalError("Execution error: \(error.description())")
    }
}
