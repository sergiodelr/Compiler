//
// Created by sergio on 23/10/2020.
//

import Foundation

// Describes the requirements for an address allocator. Must have an initializer with the initial address of the
// memory section and the number of addresses per type. Must also have a method to get next available address
// for the given type.
protocol AddressAllocator {
    init(startAddress: Int, addressesPerType: Int)
    func getNext(_ type: DataType) -> Int
}

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

    // AddressAllocator
    required public init(startAddress: Int, addressesPerType: Int) {
        intStartAddress = startAddress
        floatStartAddress = startAddress + addressesPerType
        charStartAddress = startAddress + 2 * addressesPerType
        boolStartAddress = startAddress + 3 * addressesPerType
        upperLimit = startAddress + 4 * addressesPerType

        nextCounter[.intType] = intStartAddress
        nextCounter[.floatType] = floatStartAddress
        nextCounter[.charType] = charStartAddress
        nextCounter[.boolType] = boolStartAddress

        availableAddresses[.intType] = Set<Int>()
        availableAddresses[.floatType] = Set<Int>()
        availableAddresses[.charType] = Set<Int>()
        availableAddresses[.boolType] = Set<Int>()
    }

    public func getNext(_ type: DataType) -> Int {
        guard [DataType.intType, DataType.floatType, DataType.charType, DataType.boolType].contains(type) else {
            // TODO: Throw error
            return 0 // Dummy return.
        }
        let res: Int
        // After guard, availableAddresses is guaranteed to contain key.
        if availableAddresses[type]!.isEmpty {
            // return current counter and increase it.
            res = nextCounter[type]!
            nextCounter[type] = res + 1
        } else {
            // return an address from availableAddresses.
            // TODO: make sure set mutates when removing addresses.
            res = availableAddresses[type]!.removeFirst()
        }
        return res
    }

    // Public
    public func recycle(_ address: Int) {
        let type: DataType
        switch address {
        case intStartAddress ..< floatStartAddress:
            type = .intType
        case floatStartAddress ..< charStartAddress:
            type = .floatType
        case charStartAddress ..< boolStartAddress:
            type = .charType
        case boolStartAddress ..< upperLimit:
            type = .boolType
        default:
            // TODO: Throw error.
            return // Dummy return
        }

        // Dictionaries are guaranteed to contain type.
        if address == nextCounter[type]! - 1 {
            nextCounter[type] = address
        } else {
            // TODO: Make sure set is updated.
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
    // Initial addresses for each type.
    private let intStartAddress: Int
    private let floatStartAddress: Int
    private let charStartAddress: Int
    private let boolStartAddress: Int
    
    // AddressAllocator
    required init(startAddress: Int, addressesPerType: Int) {
        intStartAddress = startAddress
        floatStartAddress = startAddress + addressesPerType
        charStartAddress = startAddress + 2 * addressesPerType
        boolStartAddress = startAddress + 3 * addressesPerType
        upperLimit = startAddress + 4 * addressesPerType

        nextCounter[.intType] = intStartAddress
        nextCounter[.floatType] = floatStartAddress
        nextCounter[.charType] = charStartAddress
        nextCounter[.boolType] = boolStartAddress
    }

    func getNext(_ type: DataType) -> Int {
        guard [DataType.intType, DataType.floatType, DataType.charType, DataType.boolType].contains(type) else {
            // TODO: Throw error
            return 0 // Dummy return.
        }
        // Type is guaranteed to be a key.
        let res = nextCounter[type]!
        nextCounter[type] = res + 1
        return res
    }
}