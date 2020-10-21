//
// Created by sergio on 19/10/2020.
//

import Foundation

// An operator that the language's virtual machine will interpret. Can be arithmetic operators, goTos, etc.
public enum VMOperator {
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
}

// Represents a quadruple, which contains a VM operator and the virtual address of its first argument, its second one,
// and its result.
public struct Quadruple {
    public var instruction: VMOperator
    public var first: Int?
    public var second: Int?
    public var res: Int?
}