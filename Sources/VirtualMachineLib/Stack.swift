//
// Created by sergio on 20/10/2020.
//

import Foundation

// Protocol defining the requirements for a stack.
protocol Stackable {
    associatedtype Element
    var top: Element? { get }
    mutating func push(_ item: Element)
    mutating func pop() -> Element?
}

// LIFO data structure.
public class Stack<Element>: Stackable {
    // Private
    private var items: [Element]

    // Public
    public var isEmpty: Bool {
        return items.isEmpty
    }

    public init() {
        items = [Element]()
    }

    // Stackable
    public var top: Element? {
        return items.last
    }

    public func push(_ item: Element) {
        items.append(item)
    }

    @discardableResult
    public func pop() -> Element? {
        return items.popLast()
    }
}