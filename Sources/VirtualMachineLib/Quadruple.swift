//
// Created by sergio on 19/10/2020.
//

import Foundation

// An operator that the language's virtual machine will interpret. Can be arithmetic operators, goTos, etc.
public enum VMOperator: String {
    case add
    case subtract
    case divide
    case multiply
    case and
    case or
    case not
    case positive
    case negative
    case equal
    case notEqual
    case lessThan
    case greaterThan
    case lessEqual
    case greaterEqual
    case assign
    case cons
    case append
    case goToFalse
    case goToTrue
    case goTo
    case ret
    case placeholder
}

// Represents a quadruple, which contains a VM operator and the virtual address of its first argument, its second one,
// and its result.
public struct Quadruple: CustomStringConvertible {
    public var instruction: VMOperator
    public var first: Int?
    public var second: Int?
    public var res: Int?

    public var description: String {
        return "<\(instruction), \(String(first)), \(String(second)), \(String(res))>"
    }

    public init(instruction: VMOperator, first: Int?, second: Int?, res: Int?) {
        self.instruction = instruction
        self.first = first
        self.second = second
        self.res = res
    }
}

// Convenience initializer for optional Ints in quadruples.
extension String {
    init(_ optionalInt: Int?) {
        if let value = optionalInt {
            self = String(value)
        } else {
            self = "_"
        }
    }
}