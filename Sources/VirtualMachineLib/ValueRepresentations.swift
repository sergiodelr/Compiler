//
// Created by sergio on 11/11/2020.
//

import Foundation

// The actual structure a function will be stored with and used during runtime.
struct FuncValue {
    // Structure to capture the function's context.
    struct FuncContext {
        var intValues: [Int: Int]
        var floatValues: [Int: Float]
        var charValues: [Int: String]
        var boolValues: [Int: Bool]
        var listValues: [Int: ListValue]
        var funcValues: [Int: FuncValue]
    }
    // The starting instruction in the function.
    let instructionPointer: Int
    let paramCount: Int
    let tempCount: Int
    let constCount: Int
    var context: FuncContext
}

// The actual structure a list will be stored with and used during runtime.
struct ListValue {
    // List node's value address.
    let value: Int?
    // Next node.
    var next: Int?
}