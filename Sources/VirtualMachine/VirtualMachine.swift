//
// Created by sergio on 12/11/2020.
//

import Foundation
import VirtualMachineLib

public class VirtualMachine {
    let instructionQueue: InstructionQueue
    var instructionPointer = 0
    var savedInstructionPointers = Stack<Int>()
    var returnValue: Any = () // Initialized to arbitrary value.
    var argList = [Any]()
    var memory: VirtualMemory

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

        memory = VirtualMemory(literals: literals)
    }

    public func run() {
        memory.pushLocal()
        runQuads()
    }

    func runQuads() {
        program: while true {
            let quad = instructionQueue[instructionPointer]
            // Optionals are force unwrapped because they are guaranteed to contain a value unless program file is
            // corrupt.
            // TODO: Validate that quadruples contain expected values.
            switch quad.instruction {
            case .add:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                add(firstVal, secondVal, resultAddress: quad.res!)
            case .subtract:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                subtract(firstVal, secondVal, resultAddress: quad.res!)
            case .multiply:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                multiply(firstVal, secondVal, resultAddress: quad.res!)
            case .divide:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                divide(firstVal, secondVal, resultAddress: quad.res!)
            case .positive:
                let val = memory[quad.first!]!
                // TODO: Remove this patch when pattern matching is available.
                if let listVal = val as? ListValue {
                    cdr(listVal, resultAddress: quad.res!)
                } else {
                    memory[quad.res!] = val
                }
            case .negative:
                let val = memory[quad.first!]!
                // TODO: Remove this patch when pattern matching is available.
                if let listVal = val as? ListValue {
                    car(listVal, resultAddress: quad.res!)
                } else {
                    negative(val, resultAddress: quad.res!)
                }
            case .equal:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                equal(firstVal, secondVal, resultAddress: quad.res!)
            case .notEqual:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                notEqual(firstVal, secondVal, resultAddress: quad.res!)
            case .lessThan:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                lessThan(firstVal, secondVal, resultAddress: quad.res!)
            case .greaterThan:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                greaterThan(firstVal, secondVal, resultAddress: quad.res!)
            case .lessEqual:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                lessEqual(firstVal, secondVal, resultAddress: quad.res!)
            case .greaterEqual:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                greaterEqual(firstVal, secondVal, resultAddress: quad.res!)
            case .and:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                // And operator must be sent as closure because of invalid autoclosure syntax.
                write(binaryBoolOperation: {$0 && $1}, firstVal, secondVal, resultAddress: quad.res!)
            case .or:
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                // And operator must be sent as closure because of invalid autoclosure syntax.
                write(binaryBoolOperation: {$0 || $1}, firstVal, secondVal, resultAddress: quad.res!)
            case .not:
                let val = memory[quad.first!]!
                not(val, resultAddress: quad.res!)
            case .cons:
                let firstVal = quad.first!
                let secondVal = quad.second!
                cons(firstVal, secondVal, resultAddress: quad.res!)
            case .append:
                // TODO: Finish append functionality.
                let firstVal = memory[quad.first!]!
                let secondVal = memory[quad.second!]!
                append(firstVal, secondVal, resultAddress: quad.res!)
            case .assign:
                let val = memory[quad.first!]!
                let addr = quad.res!
                memory[addr] = cast(val, toTypeInAddress: addr)
            case .print:
                let val = memory[quad.res!]!
                printValue(val)
            case .read:
                let addr = quad.res!
                let input = readLine()
                read(input, resultAddress: addr)
            case .goTo:
                let instruction = quad.res!
                instructionPointer = instruction - 1 // One will be added to instructionPointer outside of switch.
            case .goToFalse:
                let val = memory[quad.first!]!
                guard let boolVal = val as? Bool else {
                    fatalError("Value error")
                }
                if !boolVal {
                    let instruction = quad.res!
                    instructionPointer = instruction - 1 // One will be added to instructionPointer outside of switch.
                }
            case .goToTrue:
                let val = memory[quad.first!]!
                guard let boolVal = val as? Bool else {
                    fatalError("Value error")
                }
                if boolVal {
                    let instruction = quad.res!
                    instructionPointer = instruction - 1 // One will be added to instructionPointer outside of switch.
                }
            case .importCon:
                let funcVal = memory[quad.first!]! as! FuncValue
                let val = memory[quad.second!]!
                memory[quad.first!] = importValue(val, toFunction: funcVal, toAddress: quad.res!)
            case .arg:
                let val = memory[quad.first!]!
                argList.append(val)
            case .alloc:
                break
            case .call:
                let funcVal = memory[quad.res!]! as! FuncValue
                savedInstructionPointers.push(instructionPointer)
                // One will be added to instructionPointer outside of switch.
                instructionPointer = funcVal.instructionPointer - 1
                // Push new local memory, initialize parameters and context. Reset argument list.
                memory.pushLocal()
                // Get last elements in argList.
                let funcArgs = argList[(argList.count - funcVal.paramCount)...]
                for (address, value) in zip(funcVal.paramAddresses, funcArgs) {
                    memory[address] = cast(value, toTypeInAddress: address)
                }
                importContext(funcVal.context)
                argList.removeLast(funcVal.paramCount)
            case .ret:
                // Save return value, pop local memory and return to previous instruction pointer.
                returnValue = memory[quad.res!]!
                memory.popLocal()
                instructionPointer = savedInstructionPointers.pop()!
            case .receiveRes:
                // Set return value to the given memory address.
                let resultAddress = quad.res!
                memory[resultAddress] = cast(returnValue, toTypeInAddress: resultAddress)
            case .end:
                break program
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
            memory[resultAddress] = !v
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

    func cons(_ left: Int, _ right: Int, resultAddress: Int) {
        // First, copy value of first operand to dynamic memory. Save its address.
        let valDynamicAddress = memory.nextDynamicAddress
        memory.writeDynamicValue(memory[left]!)
        // Create new ListCell with value address and next cell address.
        let listVal = memory[right]! as! ListValue
        let listCell = ListCell(value: valDynamicAddress, next: listVal.value!)
        // Create new ListValue pointing to the list cell. Write list cell in dynamic memory.
        let cellDynamicAddress = memory.nextDynamicAddress
        memory.writeDynamicValue(listCell)
        let newListVal = ListValue(value: cellDynamicAddress)
        memory[resultAddress] = newListVal
    }

    func car(_ val: ListValue, resultAddress: Int) {
        guard let cellAddr = val.value else {
            fatalError("Corrupted list.")
        }
        guard let listCell = memory.readDynamicValue(inAddress: cellAddr) as? ListCell,
              listCell.value != nil else {
            fatalError("Empty list")
        }
        let internalVal = memory.readDynamicValue(inAddress: listCell.value!)
        memory[resultAddress] = internalVal
    }

    func cdr(_ val: ListValue, resultAddress: Int) {
        guard let cellAddr = val.value else {
            fatalError("Corrupted list.")
        }
        guard let listCell = memory.readDynamicValue(inAddress: cellAddr) as? ListCell,
              listCell.value != nil  else {
            fatalError("Empty list")
        }
        let nextListVal = ListValue(value: listCell.next!)
        memory[resultAddress] = nextListVal
    }

    // TODO: Implement
    func append(_ left: Any, _ right: Any, resultAddress: Int) {
        guard let leftList = left as? ListValue,
              let rightList = right as? ListValue,
              let leftAddr = leftList.value,
              let rightAddr = rightList.value else {
            fatalError("Corrupted list.")
        }
        let firstLeftCell = memory.readDynamicValue(inAddress: leftAddr) as! ListCell

        let listAddress: Int
        if firstLeftCell.value == nil {
            // If first list is empty, assign right cell address.
            listAddress = rightAddr
        } else {
            // Else copy first list and append right cell address at the end.
            listAddress = copyList(withFirstCell: firstLeftCell, finalAddress: rightAddr)
        }
        memory[resultAddress] = ListValue(value: listAddress)
    }

    // Convenience function to copy the first list and append the second to the copy. First list must not be empty.
    // Returns address of the resulting list.
    func copyList(withFirstCell cell: ListCell, finalAddress secondAddress: Int) -> Int {
        guard let nextAddr = cell.next,
              let nextCell = memory.readDynamicValue(inAddress: nextAddr) as? ListCell else {
            fatalError("Corrupted list.")
        }
        // Copy value to dynamic memory.
        let valDynamicAddress = memory.nextDynamicAddress
        memory.writeDynamicValue(memory.readDynamicValue(inAddress: cell.value!))
        // Create new ListCell with value address and next cell address.
        let listCell: ListCell
        if nextCell.value == nil {
            // If next cell is empty, append secondAddress.
            listCell = ListCell(value: valDynamicAddress, next: secondAddress)
        } else {
            // Else copy the rest of the list recursively.
            listCell = ListCell(
                    value: valDynamicAddress,
                    next: copyList(withFirstCell: nextCell, finalAddress: secondAddress))
        }

        let cellDynamicAddress = memory.nextDynamicAddress
        memory.writeDynamicValue(listCell)
        return cellDynamicAddress
    }

    func printValue(_ val: Any) {
        // Converts the given value to a string.
        func stringVal(_ val: Any) -> String {
            var result = String()
            switch val {
            case let listVal as ListValue:
                result = "["
                guard let cellAddr = listVal.value else {
                    fatalError("Corrupted list.")
                }
                var listCell = memory.readDynamicValue(inAddress: cellAddr) as! ListCell

                result += stringVal(listCell)
                if result.last == " " {
                    // If last character is a space, remove last space and last comma.
                    result.removeLast()
                    result.removeLast()
                }
                result += "]"
            case var listCell as ListCell:
                while let valAddress = listCell.value {
                    result += stringVal(memory.readDynamicValue(inAddress: valAddress)) + ", "
                    listCell = memory.readDynamicValue(inAddress: listCell.next!) as! ListCell
                }
            case let v as Int:
                result = String(v)
            case let v as Float:
                result = String(v)
            case let v as Bool:
                result = String(v)
            default:
                result = val as! String
            }
            return result
        }
        print(stringVal(val))
    }

    func read(_ input: String?, resultAddress: Int) {
        guard let input = input, !input.isEmpty else {
            fatalError("Read error")
        }
        if let val = castInputString(input, toTypeInAddress: resultAddress) {
            memory[resultAddress] = val
        } else {
            fatalError("Read error")
        }
    }

    // Writes the result of the given numeric operation to the given address.
    func write<T: SignedNumeric>(numericOperation op: (T, T) -> T, _ l: T, _ r: T, toAddress addr: Int) {
        memory[addr] = cast(op(l, r), toTypeInAddress: addr)
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
        let equalLists: Bool
        // Check if any list value contains an empty pointer.
        guard let lVal = l.value, let rVal = r.value else {
            fatalError("Corrupted lists.")
        }

        // If not, cells contain values and must be checked.
        let lCell = memory.readDynamicValue(inAddress: lVal) as! ListCell
        let rCell = memory.readDynamicValue(inAddress: rVal) as! ListCell
        equalLists = equals(lCell, rCell)

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
            fatalError("Type error.")
        }
    }

    private func importValue(_ val: Any, toFunction funcVal: FuncValue, toAddress addr: Int) -> FuncValue {
        var newFuncVal = funcVal
        switch val {
        case let v as Int:
            newFuncVal.context.intValues[addr] = v
        case let v as Float:
            newFuncVal.context.floatValues[addr] = v
        case let v as String:
            newFuncVal.context.charValues[addr] = v
        case let v as Bool:
            newFuncVal.context.boolValues[addr] = v
        case let v as ListValue:
            newFuncVal.context.listValues[addr] = v
        case let v as FuncValue:
            newFuncVal.context.funcValues[addr] = v
        default:
            fatalError("Value error.")
        }
        return newFuncVal
    }

    private func importContext(_ context: FuncValue.FuncContext) {
        var memoryMapping = [Int: Any]()
        // Values are guaranteed not to collide.
        memoryMapping.merge(context.intValues){ (current, _) in current }
        memoryMapping.merge(context.floatValues){ (current, _) in current }
        memoryMapping.merge(context.charValues){ (current, _) in current }
        memoryMapping.merge(context.boolValues){ (current, _) in current }
        memoryMapping.merge(context.funcValues){ (current, _) in current }
        memoryMapping.merge(context.listValues){ (current, _) in current }

        for (addr, val) in memoryMapping {
            memory[addr] = val
        }
    }
}

// Convenience methods.
extension VirtualMachine {
    // Casts the given string to the value contained in the given address. String must not be empty.
    func castInputString(_ input: String, toTypeInAddress address: Int) -> Any? {
        let segmentAddr = address % MemoryPointer.segmentSize
        switch segmentAddr {
        case MemoryPointer.intStartAddress ..< MemoryPointer.floatStartAddress:
            return Int(input)
        case MemoryPointer.floatStartAddress ..< MemoryPointer.charStartAddress:
            return Float(input)
        case MemoryPointer.charStartAddress ..< MemoryPointer.boolStartAddress:
            return String(input.first!)
        case MemoryPointer.boolStartAddress ..< MemoryPointer.funcStartAddress:
            return Bool(input)
        default:
            break
        }
        // TODO: Error
        fatalError("Read error.")
    }

    // Casts the given value depending on the address it will be written to.
    func cast(_ val: Any, toTypeInAddress address: Int ) -> Any {
        let segmentAddr = address % MemoryPointer.segmentSize
        switch segmentAddr {
        case MemoryPointer.intStartAddress ..< MemoryPointer.floatStartAddress:
            // val must be cast to call initializer.
            if val is Float {
                return Int(val as! Float)
            }
        case MemoryPointer.floatStartAddress ..< MemoryPointer.charStartAddress:
            // val must be cast to call initializer.
            if val is Int {
                return Float(val as! Int)
            }
        default:
            break
        }
        return val
    }

    // Convenience method for list equality.
    // TODO: Refactor ListValue to conform to Equatable instead.
    func equals(_ l: ListCell, _ r: ListCell) -> Bool {
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
            let lVal = memory.readDynamicValue(inAddress: lValAddr)
            let rVal = memory.readDynamicValue(inAddress: rValAddr)
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
                // Check if any list value contains an empty pointer.
                guard let lVal = lCast.value, let rVal = rCast.value else {
                    fatalError("Corrupted lists.")
                }
                // If not, cells contain values and must be checked.
                let lCell = memory.readDynamicValue(inAddress: lVal) as! ListCell
                let rCell = memory.readDynamicValue(inAddress: rVal) as! ListCell
                equalVal = equals(lCell, rCell)
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
                   let lNextCell = memory.readDynamicValue(inAddress: lNextAddr) as? ListCell,
                   let rNextCell = memory.readDynamicValue(inAddress: rNextAddr) as? ListCell {
                    // Check next node recursively.
                    return equals(lNextCell, rNextCell)
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