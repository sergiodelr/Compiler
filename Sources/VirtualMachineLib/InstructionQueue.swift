//
// Created by sergio on 19/10/2020.
//

import Foundation

// The instruction queue which contains quadruples in the order of execution. Contains convenience methods for its
// construction.
public class InstructionQueue: Codable {
    // Private
    // Internal instruction queue.
    private var queue: [Quadruple]

    // Public
    // Next index in the queue.
    public var nextInstruction: Int {
        return queue.count
    }

    public var count: Int {
        return nextInstruction
    }

    public init() {
        queue = [Quadruple]()
    }

    // Convenience subscript syntax.
    public subscript(index: Int) -> Quadruple {
        get {
            return queue[index]
        }
        set {
            queue[index] = newValue
        }
    }

    // Pushes a new element at the end of the instruction queue.
    public func push(_ quadruple: Quadruple) {
        queue.append(quadruple)
    }

    // Sets the result of the quadruple at the given index to the given result value.
    public func fillResult(at index: Int, result: Int) {
        queue[index].res = result
    }
}