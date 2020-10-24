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
    private var tempAllocators: Stack<TempAddressAllocator>
    // Global const allocator.
    private var globalAllocator: VirtualAddressAllocator
    // Local const allocators.
    private var localAllocators: Stack<VirtualAddressAllocator>

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
        tempAllocators = Stack<TempAddressAllocator>()
        tempAllocators.push(TempAddressAllocator())
        globalAllocator = Stack<VirtualAddressAllocator>()

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
        symbolTable[name] = SymbolTable.Entry(name: name, dataType: type, kind: kind, address: )
    }

    // Creates a new symbol table and sets its parent to the previous one.
    public func newSymbolTable() {
        symbolTable = SymbolTable(parent: symbolTable)
        tempCreators.push(TempAddressAllocator())
    }

    // Returns to the parent symbol table if there is one, deleting the current one.
    public func deleteSymbolTable() {
        if let parentTable = symbolTable.parent {
            symbolTable = parentTable
            tempCreators.pop()
        }
    }
}
