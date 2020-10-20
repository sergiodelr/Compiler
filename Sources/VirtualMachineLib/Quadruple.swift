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
    case assign
    case cons
    case append
    case goToFalse
    case goToTrue
    case goTo
}

// Represents a quadruple, which contains a VM operator and the address of its first argument, its second one, and its
// result.
public struct Quadruple {
    public var instruction: VMOperator
    public var first: Int?
    public var second: Int?
    public var res: Int?
}