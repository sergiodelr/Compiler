//
// Created by sergio on 23/10/2020.
//

import Foundation
import VirtualMachineLib

// Describes the requirements for an address allocator. Must have an initializer with the initial address of the
// memory section and the number of addresses per type. Must also have a method to get next available address
// for the given type.
protocol AddressAllocator {
    init(startAddress: Int, addressesPerType: Int)
    func getNext(_ type: DataType) -> Int
    var maxIntCount: Int  { get }
    var maxFloatCount: Int { get }
    var maxCharCount: Int { get }
    var maxBoolCount: Int { get }
    var maxFuncCount: Int { get }
}

// TODO: Refactor this as a subclass of VirtualAddressAllocator
// Handles virtual memory for temporary variables. Can allocate more memory addresses or recycle them as needed.
public class TempAddressAllocator: AddressAllocator {
    // Private
    // The next memory counter for each data type.
    private var nextCounter = [DataType: Int]()
    // The available recycled addresses for each data type.
    private var availableAddresses = [DataType: Set<Int>]()
    // Upper address limit. Addresses must be less than this.
    private let upperLimit: Int
    // Initial addresses for each type.
    private let intStartAddress: Int
    private let floatStartAddress: Int
    private let charStartAddress: Int
    private let boolStartAddress: Int
    private let functionStartAddress: Int
    // Address counts.
    // If the new count is greater than the current max count, max count takes its value.
    private var intCount = 0 {
        willSet { if newValue > maxIntCount { maxIntCount = newValue } }
    }
    private var floatCount = 0 {
        willSet { if newValue > maxFloatCount { maxFloatCount = newValue } }
    }
    private var charCount = 0 {
        willSet { if newValue > maxCharCount { maxCharCount = newValue } }
    }
    private var boolCount = 0 {
        willSet { if newValue > maxBoolCount { maxBoolCount = newValue } }
    }
    private var funcCount = 0 {
        willSet { if newValue > maxFuncCount { maxFuncCount = newValue } }
    }

    // Gets next function address.
    private func getNextFunc() -> Int {
        let res: Int
        let type = DataType.funcType(paramTypes: [], returnType: .noneType)
        // availableAddresses is guaranteed to contain key.
        if availableAddresses[type]!.isEmpty {
            // return current counter and increase it.
            res = nextCounter[type]!
            nextCounter[type] = res + 1
            addToCount(type: type, amount: 1)
        } else {
            // return an address from availableAddresses.
            res = availableAddresses[type]!.removeFirst()
        }
        return res
    }

    // Adds the given amount to the count of the given type.
    private func addToCount(type: DataType, amount: Int) {
        switch type {
        case .intType:
            intCount += amount
        case .floatType:
            floatCount += amount
        case .charType:
            charCount += amount
        case .boolType:
            boolCount += amount
        case .funcType:
            funcCount += amount
        default:
            return
        }
    }

    // AddressAllocator
    public private(set) var maxIntCount = 0
    public private(set) var maxFloatCount = 0
    public private(set) var maxCharCount = 0
    public private(set) var maxBoolCount = 0
    public private(set) var maxFuncCount = 0

    required public init(startAddress: Int, addressesPerType: Int) {
        intStartAddress = startAddress
        floatStartAddress = startAddress + addressesPerType
        charStartAddress = startAddress + 2 * addressesPerType
        boolStartAddress = startAddress + 3 * addressesPerType
        functionStartAddress = startAddress + 4 * addressesPerType
        upperLimit = startAddress + 5 * addressesPerType

        nextCounter[.intType] = intStartAddress
        nextCounter[.floatType] = floatStartAddress
        nextCounter[.charType] = charStartAddress
        nextCounter[.boolType] = boolStartAddress
        nextCounter[.funcType(paramTypes: [], returnType: .noneType)] = functionStartAddress

        availableAddresses[.intType] = Set<Int>()
        availableAddresses[.floatType] = Set<Int>()
        availableAddresses[.charType] = Set<Int>()
        availableAddresses[.boolType] = Set<Int>()
        availableAddresses[.funcType(paramTypes: [], returnType: .noneType)] = Set<Int>()
    }

    // Gets the next address from the specified type.
    public func getNext(_ type: DataType) -> Int {
        if case DataType.funcType = type {
            return getNextFunc()
        }

        guard [DataType.intType, DataType.floatType, DataType.charType, DataType.boolType].contains(type) else {
            SemanticError.handle(.internalError)
            return 0 // Dummy return.
        }
        let res: Int
        // After guard, availableAddresses is guaranteed to contain key.
        if availableAddresses[type]!.isEmpty {
            // return current counter and increase it.
            res = nextCounter[type]!
            nextCounter[type] = res + 1
            addToCount(type: type, amount: 1)
        } else {
            // return an address from availableAddresses.
            res = availableAddresses[type]!.removeFirst()
        }
        return res
    }

    // Public
    // Recycles temporary addresses or returns if address is not within temp ranges.
    public func recycle(_ address: Int) {
        let type: DataType
        switch address {
        case intStartAddress ..< floatStartAddress:
            type = .intType
        case floatStartAddress ..< charStartAddress:
            type = .floatType
        case charStartAddress ..< boolStartAddress:
            type = .charType
        case boolStartAddress ..< functionStartAddress:
            type = .boolType
        case functionStartAddress ..< upperLimit:
            type = .funcType(paramTypes: [], returnType: .noneType)
        default:
            // If it is not a temp address, return.
            return
        }

        // Dictionaries are guaranteed to contain type.
        if address == nextCounter[type]! - 1 {
            nextCounter[type] = address
            addToCount(type: type, amount: -1)
        } else {
            availableAddresses[type]!.insert(address)
        }
    }
}

// Allocator for global and local addresses.
public class VirtualAddressAllocator: AddressAllocator {
    // Private
    // The next memory counter for each data type.
    private var nextCounter = [DataType: Int]()
    // Upper address limit. Addresses must be less than this.
    private let upperLimit: Int
    // Addresses per type.
    private let addressesPerType: Int
    // Initial addresses for each type.
    private let intStartAddress: Int
    private let floatStartAddress: Int
    private let charStartAddress: Int
    private let boolStartAddress: Int
    private let functionStartAddress: Int

    // Gets next function address.
    private func getNextFunc() -> Int {
        let type = DataType.funcType(paramTypes: [], returnType: .noneType)
        // Type is guaranteed to be a key.
        let res = nextCounter[type]!
        nextCounter[type] = res + 1
        return res
    }

    // AddressAllocator
    // The max amount of addresses allocated for each type is equal to the next address % the amount of addresses.
    public var maxIntCount: Int { return nextCounter[.intType]! % addressesPerType }
    public var maxFloatCount: Int { return nextCounter[.floatType]! % addressesPerType }
    public var maxCharCount: Int { return nextCounter[.charType]! % addressesPerType }
    public var maxBoolCount: Int { return nextCounter[.boolType]! % addressesPerType }
    public var maxFuncCount: Int {
        return nextCounter[.funcType(paramTypes: [], returnType: .noneType)]! % addressesPerType
    }

    required init(startAddress: Int, addressesPerType: Int) {
        self.addressesPerType = addressesPerType
        intStartAddress = startAddress
        floatStartAddress = startAddress + addressesPerType
        charStartAddress = startAddress + 2 * addressesPerType
        boolStartAddress = startAddress + 3 * addressesPerType
        functionStartAddress = startAddress + 4 * addressesPerType
        upperLimit = startAddress + 5 * addressesPerType

        nextCounter[.intType] = intStartAddress
        nextCounter[.floatType] = floatStartAddress
        nextCounter[.charType] = charStartAddress
        nextCounter[.boolType] = boolStartAddress
        nextCounter[.funcType(paramTypes: [], returnType: .noneType)] = functionStartAddress
    }

    func getNext(_ type: DataType) -> Int {
        if case DataType.funcType = type {
            return getNextFunc()
        }

        guard [DataType.intType, DataType.floatType, DataType.charType, DataType.boolType].contains(type) else {
            SemanticError.handle(.internalError)
            return 0 // Dummy return.
        }
        // Type is guaranteed to be a key.
        let res = nextCounter[type]!
        nextCounter[type] = res + 1
        return res
    }
}