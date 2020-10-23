//
// Created by sergio on 22/10/2020.
//

import Foundation
import VirtualMachineLib

// Generates quadruples and adds them to the instruction queue for the VM. Does semantic checks.
public class CodeGenerator {
    var instructionQueue: InstructionQueue
    // Stack for operators in expressions
    var operatorStack: Stack<LangOperator>
    // Stack for operands in expressions. Contains the operands' virtual address.
    var operandStack: Stack<Int>
    // Jump stack for conditional statements.
    var jumpStack: Stack<Int>
    // Global symbol table.
    var globalTable: SymbolTable
    // Current symbol table.
    var symbolTable: SymbolTable
    
    public init() {
        instructionQueue = InstructionQueue()
        operatorStack = Stack<LangOperator>()
        operandStack = Stack<Int>()
        jumpStack = Stack<Int>()
        globalTable = SymbolTable()
        symbolTable = globalTable
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
    }

    // Returns to the parent symbol table if there is one, deleting the current one.
    public func deleteSymbolTable() {
        if let parentTable = symbolTable.parent {
            symbolTable = parentTable
        }
    }
}
