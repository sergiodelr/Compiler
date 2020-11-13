//
// Created by sergio on 11/11/2020.
//

import Foundation

// The actual structure a function will be stored with and used during runtime.
public struct FuncValue: Codable {
    // Structure to capture the function's context.
    struct FuncContext: Codable {
        var intValues: [Int: Int]
        var floatValues: [Int: Float]
        var charValues: [Int: String]
        var boolValues: [Int: Bool]
        var listValues: [Int: ListValue]
        var funcValues: [Int: FuncValue]

        init() {
            intValues = [Int: Int]()
            floatValues = [Int: Float]()
            charValues = [Int: String]()
            boolValues = [Int: Bool]()
            listValues = [Int: ListValue]()
            funcValues = [Int: FuncValue]()
        }
    }
    // The starting instruction in the function.
    let instructionPointer: Int
    let paramCount: Int
    let tempCount: Int
    let constCount: Int
    var context: FuncContext

    public init(fromValueEntry entry: FuncValueEntry) {
        instructionPointer = entry.value! as! Int
        paramCount = entry.paramCount
        tempCount = entry.tempCount.values.reduce(0, +) // Sum all temps.
        constCount = entry.constCount.values.reduce(0, +) // Sum all consts.
        context = FuncContext()
    }
}

// The actual structure a list will be stored with and used during runtime.
public struct ListValue: Codable, Equatable {
    // List node's value address.
    public let value: Int?
    // Next node.
    public var next: Int?

    public init(fromValueEntry entry: ListValueEntry) {
        value = entry.value as! Int?
        next = entry.next
    }
}