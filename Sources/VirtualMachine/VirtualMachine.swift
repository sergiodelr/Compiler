//
// Created by sergio on 12/11/2020.
//

import Foundation
import VirtualMachineLib

public class VirtualMachine {
    let instructionQueue: InstructionQueue
    var instructionPointer = 0

    var memory: Memory

    public init(programContainer: ProgramContainer) {
        instructionQueue = programContainer.instructionQueue
        // Create a literal dictionary that contains all literals. It is guaranteed that there will be no key
        // collisions.
        var literals = [Int: Any]()
        literals.merge(programContainer.intLiterals) { (current, _)  in current }
        literals.merge(programContainer.floatLiterals) { (current, _)  in current }
        literals.merge(programContainer.charLiterals) { (current, _)  in current }
        literals.merge(programContainer.boolLiterals) { (current, _)  in current }
        literals.merge(programContainer.funcLiterals) { (current, _)  in current }
        literals.merge(programContainer.listLiterals) { (current, _)  in current }
        
        memory = Memory(literals: literals)
    }

    public func run() {
        runQuads()
    }

    func runQuads() {
        while true {
            let quad = instructionQueue[instructionPointer]
            // Optionals are force unwrapped because they are guaranteed to contain a value unless program file is
            // corrupt.
            // TODO: Validate that quadruples contain expected values.
            switch quad.instruction {
            case .add:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                add(firstVal, secondVal, resultAddress: quad.res!)
            case .subtract:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                subtract(firstVal, secondVal, resultAddress: quad.res!)
            case .multiply:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                multiply(firstVal, secondVal, resultAddress: quad.res!)
            case .divide:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                divide(firstVal, secondVal, resultAddress: quad.res!)
            case .positive:
                let val = memory[quad.first!]
                memory[quad.res!] = val
            case .negative:
                let val = memory[quad.first!]
                negative(val, resultAddress: quad.res!)
            case .equal:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                equal(firstVal, secondVal, resultAddress: quad.res!)
            case .notEqual:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                notEqual(firstVal, secondVal, resultAddress: quad.res!)
            case .lessThan:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                lessThan(firstVal, secondVal, resultAddress: quad.res!)
            case .greaterThan:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                greaterThan(firstVal, secondVal, resultAddress: quad.res!)
            case .lessEqual:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                lessEqual(firstVal, secondVal, resultAddress: quad.res!)
            case .greaterEqual:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                greaterEqual(firstVal, secondVal, resultAddress: quad.res!)
            case .and:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                // And operator must be sent as closure because of invalid autoclosure syntax.
                write(binaryBoolOperation: {$0 && $1}, firstVal, secondVal, resultAddress: quad.res!)
            case .or:
                let firstVal = memory[quad.first!]
                let secondVal = memory[quad.second!]
                // And operator must be sent as closure because of invalid autoclosure syntax.
                write(binaryBoolOperation: {$0 || $1}, firstVal, secondVal, resultAddress: quad.res!)
            case .not:
                let val = memory[quad.first!]
                not(val, resultAddress: quad.res!)
            default:
                fatalError("Not supported.")
            }
            instructionPointer += 1
        }
    }

    func add(_ left: Any, _ right: Any, resultAddress: Int) {
        // Contents of memory must be cast before their use. Same for every other operations.
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(numericOperation: +, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(numericOperation: +, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(numericOperation: +, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(numericOperation: +, l, Float(r), toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func subtract(_ left: Any, _ right: Any, resultAddress: Int) {
        // Contents of memory must be cast before their use. Same for every other operations.
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(numericOperation: -, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(numericOperation: -, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(numericOperation: -, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(numericOperation: -, l, Float(r), toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func multiply(_ left: Any, _ right: Any, resultAddress: Int) {
        // Contents of memory must be cast before their use. Same for every other operations.
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(numericOperation: *, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(numericOperation: *, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(numericOperation: *, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(numericOperation: *, l, Float(r), toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func divide(_ left: Any, _ right: Any, resultAddress: Int) {
        // Contents of memory must be cast before their use. Same for every other operations.
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(numericOperation: /, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(numericOperation: /, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(numericOperation: /, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(numericOperation: /, l, Float(r), toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func negative(_ val: Any, resultAddress: Int) {
        switch val {
        case let v as Int:
            memory[resultAddress] = v
        case let v as Float:
            memory[resultAddress] = v
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func not(_ val: Any, resultAddress: Int) {
        if let v = val as? Bool {
            memory[resultAddress] = v
        } else {
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func equal(_ left: Any, _ right: Any, resultAddress: Int) {
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(equatableOperation: ==, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(equatableOperation: ==, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(equatableOperation: ==, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(equatableOperation: ==, l, Float(r), toAddress: resultAddress)
        case let (l, r) as (String, String):
            write(equatableOperation: ==, l, r, toAddress: resultAddress)
        case let (l, r) as (Bool, Bool):
            write(equatableOperation: ==, l, r, toAddress: resultAddress)
        case let (l, r) as (ListValue, ListValue):
            writeEquatableListOperation(equalOperation: true, l, r, toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func notEqual(_ left: Any, _ right: Any, resultAddress: Int) {
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(equatableOperation: !=, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(equatableOperation: !=, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(equatableOperation: !=, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(equatableOperation: !=, l, Float(r), toAddress: resultAddress)
        case let (l, r) as (String, String):
            write(equatableOperation: !=, l, r, toAddress: resultAddress)
        case let (l, r) as (Bool, Bool):
            write(equatableOperation: !=, l, r, toAddress: resultAddress)
        case let (l, r) as (ListValue, ListValue):
            writeEquatableListOperation(equalOperation: false, l, r, toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func lessThan(_ left: Any, _ right: Any, resultAddress: Int) {
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(comparableOperation: <, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(comparableOperation: <, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(comparableOperation: <, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(comparableOperation: <, l, Float(r), toAddress: resultAddress)
        case let (l, r) as (String, String):
            write(comparableOperation: <, l, r, toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func greaterThan(_ left: Any, _ right: Any, resultAddress: Int) {
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(comparableOperation: >, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(comparableOperation: >, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(comparableOperation: >, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(comparableOperation: >, l, Float(r), toAddress: resultAddress)
        case let (l, r) as (String, String):
            write(comparableOperation: >, l, r, toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func lessEqual(_ left: Any, _ right: Any, resultAddress: Int) {
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(comparableOperation: <=, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(comparableOperation: <=, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(comparableOperation: <=, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(comparableOperation: <=, l, Float(r), toAddress: resultAddress)
        case let (l, r) as (String, String):
            write(comparableOperation: <=, l, r, toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    func greaterEqual(_ left: Any, _ right: Any, resultAddress: Int) {
        switch (left, right) {
        case let (l, r) as (Int, Int):
            write(comparableOperation: >=, l, r, toAddress: resultAddress)
        case let (l, r) as (Int, Float):
            write(comparableOperation: >=, Float(l), r, toAddress: resultAddress)
        case let (l, r) as (Float, Float):
            write(comparableOperation: >=, l, r, toAddress: resultAddress)
        case let (l, r) as (Float, Int):
            write(comparableOperation: >=, l, Float(r), toAddress: resultAddress)
        case let (l, r) as (String, String):
            write(comparableOperation: >=, l, r, toAddress: resultAddress)
        default:
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }

    // Writes the result of the given numeric operation to the given address.
    func write<T: SignedNumeric>(numericOperation op: (T, T) -> T, _ l: T, _ r: T, toAddress addr: Int) {
        memory[addr] = op(l, r)
    }

    // Writes the result of the given equatable operation to the given address.
    func write<T: Equatable>(equatableOperation op: (T, T) -> Bool, _ l: T, _ r: T, toAddress addr: Int) {
        memory[addr] = op(l, r)
    }

    // Writes the result of the given comparable operation to the given address.
    func write<T: Comparable>(comparableOperation op: (T, T) -> Bool, _ l: T, _ r: T, toAddress addr: Int) {
        memory[addr] = op(l, r)
    }

    // Writes the result of the given equatable operation to the given address for lists.
    // TODO: Refactor ListValue to conform to Equatable instead.
    func writeEquatableListOperation(equalOperation: Bool, _ l: ListValue, _ r: ListValue, toAddress addr: Int) {
        let equalLists = equals(l, r)
        if equalOperation {
            memory[addr] = equalLists
        } else {
            memory[addr] = !equalLists
        }
    }

    // Writes the result of a given boolean operation to the given address.
    func write(binaryBoolOperation op: (Bool, Bool) -> Bool, _ left: Any, _ right: Any, resultAddress: Int) {
        if let l = left as? Bool, let r = right as? Bool {
            memory[resultAddress] = op(l, r)
        } else {
            // TODO: Handle error.
            fatalError("Not implemented.")
        }
    }
}

// Convenience method for list equality.
// TODO: Refactor ListValue to conform to Equatable instead.
extension VirtualMachine {
    func equals(_ l: ListValue, _ r: ListValue) -> Bool {
        // Base case: Empty lists.
        if l.value == nil && l.next == nil && r.value == nil && r.next == nil {
            return true
        }
        // Base case: If one list is empty and the other isn't, return false.
        if l.value == nil && l.next == nil || r.value == nil && r.next == nil {
            return false
        }
        // If both contain a value, check next nodes recursively.
        if let lValAddr = l.value, let rValAddr = r.value {
            let lVal = memory[lValAddr]
            let rVal = memory[rValAddr]
            let equalVal: Bool

            switch (lVal, rVal) {
            case let (lCast, rCast) as (Int, Int):
                equalVal = lCast == rCast
            case let (lCast, rCast) as (Int, Float):
                equalVal = Float(lCast) == rCast
            case let (lCast, rCast) as (Float, Float):
                equalVal = lCast == rCast
            case let (lCast, rCast) as (Float, Int):
                equalVal = lCast == Float(rCast)
            case let (lCast, rCast) as (String, String):
                equalVal = lCast == rCast
            case let (lCast, rCast) as (Bool, Bool):
                equalVal = lCast == rCast
            case let (lCast, rCast) as (ListValue, ListValue):
                equalVal = equals(lCast, rCast)
            default:
                // TODO: Handle error. Lists not comparable
                fatalError()
            }
            // If values are not equal, return false.
            if !equalVal {
                return false
            } else {
                if let lNextAddr = l.next,
                   let rNextAddr = r.next,
                   let lNextNode = memory[lNextAddr] as? ListValue,
                   let rNextNode = memory[rNextAddr] as? ListValue {
                    // Check next node recursively.
                    return equals(lNextNode, rNextNode)
                } else {
                    // TODO: Handle error. Corrupted list
                    fatalError()
                }
            }
        } else {
            // TODO: Handle error. Corrupted list
            fatalError()
        }
    }
}