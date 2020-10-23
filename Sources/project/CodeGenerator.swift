//
// Created by sergio on 22/10/2020.
//

import Foundation
import VirtualMachineLib

// Generates quadruples and adds them to the instruction queue for the VM. Does semantic checks.
public class CodeGenerator {
    // Private
    private var instructionQueue: InstructionQueue
    // Global symbol table.
    private var globalTable: SymbolTable
    // Current symbol table.
    private var symbolTable: SymbolTable
    // Temp creator stack to allow for local temporaries.
    private var tempCreators: Stack<TempCreator>

    // Public
    // Stack for operators in expressions
    public var operatorStack: Stack<LangOperator>
    // Stack for operands in expressions. Contains the operands' virtual address.
    public var operandStack: Stack<Int>
    // Jump stack for conditional statements.
    public var jumpStack: Stack<Int>
    
    public init() {
        instructionQueue = InstructionQueue()
        operatorStack = Stack<LangOperator>()
        operandStack = Stack<Int>()
        jumpStack = Stack<Int>()
        globalTable = SymbolTable()
        symbolTable = globalTable
        tempCreators = Stack<TempCreator>()
        tempCreators.push(TempCreator())
    }

    // Receives a symbol name and type. Sets its kind and if it is of kind funcKind, creates a symbol table for its
    // variables. If the name already exists in the current table, a fatal error is thrown.
    public func newSymbol(name: String, type: DataType, line: Int, col: Int) {
        guard !symbolTable.find(name) else {
            SemanticError.handle(.multipleDeclaration(symbol: name), line: line, col: col)
            return // Dummy return. Fatal error will be thrown above.
        }

        let kind: SymbolTable.SymbolKind

        switch type {
        case .funcType:
            kind = .funcKind
        case .errType, .noneType:
            kind = .noKind
                // TODO: Type error.
        default:
            kind = .constKind
        }
        symbolTable[name] = SymbolTable.Entry(name: name, dataType: type, kind: kind, address: nil)
    }

    // Creates a new symbol table and sets its parent to the previous one.
    public func newSymbolTable() {
        symbolTable = SymbolTable(parent: symbolTable)
        tempCreators.push(TempCreator())
    }

    // Returns to the parent symbol table if there is one, deleting the current one.
    public func deleteSymbolTable() {
        if let parentTable = symbolTable.parent {
            symbolTable = parentTable
            tempCreators.pop()
        }
    }
}

// Handles virtual memory for temporary variables. Can allocate more memory addresses or recycle them as needed.
class TempCreator {
    // Private
    // The next memory counter for each data type.
    private var nextCounter = [DataType: Int]()
    // The available recycled addresses for each data type.
    private var availableAddresses = [DataType: Set<Int>]()

    // Public
    public init() {
        nextCounter[.intType] = MemoryPointer.tempInt
        nextCounter[.floatType] = MemoryPointer.tempFloat
        nextCounter[.charType] = MemoryPointer.tempChar
        nextCounter[.boolType] = MemoryPointer.tempBool

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
}