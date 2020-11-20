//
// Created by sergio on 11/11/2020.
//

import Foundation

// The actual structure a function will be stored with and used during runtime.
public struct FuncValue: Codable {
    // Structure to capture the function's context.
    public struct FuncContext: Codable {
        public var intValues: [Int: Int]
        public var floatValues: [Int: Float]
        public var charValues: [Int: String]
        public var boolValues: [Int: Bool]
        public var listValues: [Int: ListValue]
        public var funcValues: [Int: FuncValue]

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
    public let instructionPointer: Int
    public let paramCount: Int
    public let paramAddresses: [Int]
    let tempCount: Int
    let constCount: Int
    public var context: FuncContext

    public init(fromValueEntry entry: FuncValueEntry) {
        instructionPointer = entry.value! as! Int
        paramCount = entry.paramCount
        paramAddresses = entry.paramAddresses
        tempCount = entry.tempCount.values.reduce(0, +) // Sum all temps.
        constCount = entry.constCount.values.reduce(0, +) // Sum all consts.
        context = FuncContext()
    }
}

// The actual structure a list will be stored with and used during runtime.
public struct ListValue: Codable, Equatable {
    // List node's value address.
    public let value: Int?

    public init(value: Int?) {
        self.value = value
    }

    public init(fromValueEntry entry: ListValueEntry) {
        value = entry.value as! Int?
    }
}

// Single list cell in dynamic memory.
public struct ListCell {
    // Pointer to cell value.
    public let value: Int?
    // Pointer to next cell.
    public let next: Int?

    public init(value: Int?, next: Int?) {
        self.value = value
        self.next = next
    }
}