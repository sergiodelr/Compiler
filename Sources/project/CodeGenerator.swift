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
    // Literal allocator.
    private var literalAllocator: VirtualAddressAllocator
    // Local const allocators.
    private var localAllocators: Stack<VirtualAddressAllocator>
    // Maps from a string with a literal value to its virtual address.
    private var literalDict: [String: Int]


    // Searches for a symbol in the current table and in parent tables and returns the entry if found.
    func find(name: String) -> SymbolTable.Entry? {
        var tempTable: SymbolTable? = symbolTable
        while tempTable != nil {
            // Temp table is not nil
            if let entry = tempTable![name] {
                return entry
            }
            tempTable = tempTable!.parent
        }
        return nil
    }

    // Public
    // Stack for operators in expressions
    public var operatorStack: Stack<LangOperator>
    // Stack for operands in expressions. Contains the operands' virtual address.
    public var operandStack: Stack<Int>
    // Stack for operand types.
    public var typeStack: Stack<DataType>
    // Jump stack for conditional statements.
    public var jumpStack: Stack<Int>

    public init() {
        instructionQueue = InstructionQueue()
        operatorStack = Stack<LangOperator>()
        operandStack = Stack<Int>()
        typeStack = Stack<DataType>()
        jumpStack = Stack<Int>()
        globalTable = SymbolTable()
        symbolTable = globalTable
        literalDict = [String: Int]()

        tempAllocators = Stack<TempAddressAllocator>()
        tempAllocators.push(TempAddressAllocator(
                startAddress: MemoryPointer.tempStartAddress,
                addressesPerType: MemoryPointer.addressesPerType))
        globalAllocator = VirtualAddressAllocator(
                startAddress: MemoryPointer.globalStartAddress,
                addressesPerType: MemoryPointer.addressesPerType)
        literalAllocator = VirtualAddressAllocator(
                startAddress: MemoryPointer.literalStartAddress,
                addressesPerType: MemoryPointer.addressesPerType)
        localAllocators = Stack<VirtualAddressAllocator>()
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
            SemanticError.handle(.internalError)
        default:
            kind = .constKind
        }
        symbolTable[name] = SymbolTable.Entry(
                name: name,
                dataType: type,
                kind: kind,
                address: symbolTable === globalTable ?
                        globalAllocator.getNext(type) : localAllocators.top!.getNext(type))
    }

    // Creates a new symbol table and sets its parent to the previous one.
    public func newSymbolTable() {
        symbolTable = SymbolTable(parent: symbolTable)
        tempAllocators.push(TempAddressAllocator(
                startAddress: MemoryPointer.tempStartAddress,
                addressesPerType: MemoryPointer.addressesPerType))
        localAllocators.push(VirtualAddressAllocator(
                startAddress: MemoryPointer.localStartAddress,
                addressesPerType: MemoryPointer.addressesPerType
        ))
    }

    // Returns to the parent symbol table if there is one, deleting the current one.
    public func deleteSymbolTable() {
        if let parentTable = symbolTable.parent {
            symbolTable = parentTable
            tempAllocators.pop()
            localAllocators.pop()
        }
    }

    // Pushes a name to the operand stack and its type to the type stack.
    public func pushName(_ name: String, line: Int, col: Int) {
        let entry = find(name: name)
        guard let foundEntry = entry else {
            SemanticError.handle(.symbolNotDeclared(symbol: name), line: line, col: col)
            return // Dummy return.
        }
        operandStack.push(foundEntry.address!)
        typeStack.push(foundEntry.dataType)
    }

    // Pushes a literal to the literal map and its type to the type stack.
    public func pushLiteral(_ literal: String, type: DataType) {
        if let literalAddress = literalDict[literal] {
            operandStack.push(literalAddress)
        } else {
            let nextAddress = literalAllocator.getNext(type)
            literalDict[literal] = nextAddress
            operandStack.push(nextAddress)
        }
        typeStack.push(type)
    }

    // Pops an operand from the operand stack and its type from the type stack.
    public func popOperand() {
        operandStack.pop()
        typeStack.pop()
    }

    // Pushes an operator to the operator stack.
    public func pushOperator(_ op: LangOperator) {
        operatorStack.push(op)
    }

    // Pops an operator from the stack. Does not return it.
    public func popOperator() {
        operatorStack.pop()
    }

    // Generates a quadruple with the operator at the top of the stack and adds it to the queue if it matches the given
    // operator's precedence. If not, it does nothing. It must be an operator with two operands. If the operands' types
    // do not match, an error is thrown.
    public func generateTwoOperandsExpQuadruple(op: LangOperator, line: Int, col: Int) {
        guard let top = operatorStack.top, op.precedence() == top.precedence() else {
            return
        }
        // It is guaranteed that stacks contain elements.
        let rightOperand = operandStack.pop()!
        let rightType = typeStack.pop()!
        let leftOperand = operandStack.pop()!
        let leftType = typeStack.pop()!
        let topOperator = operatorStack.pop()!
        let resultType = ExpressionTypeTable.getDataType(op: topOperator, type1: leftType, type2: rightType)

        guard resultType != .errType else {
            // TODO: send correct types to error.
            SemanticError.handle(.typeMismatch(expected: leftType, received: rightType), line: line, col: col)
            return
        }
        if topOperator != .assgOp {
            let result = tempAllocators.top!.getNext(resultType)
            instructionQueue.push(
                    Quadruple(
                            instruction: langOperatorToVMOperator(op: topOperator),
                            first: leftOperand,
                            second: rightOperand,
                            res: result))
            operandStack.push(result)
            typeStack.push(resultType)
        } else {
            instructionQueue.push(
                    Quadruple(
                            instruction: langOperatorToVMOperator(op: topOperator),
                            first: rightOperand,
                            second: nil,
                            res: leftOperand))
        }
        tempAllocators.top!.recycle(leftOperand)
        tempAllocators.top!.recycle(rightOperand)
    }

    // Generates a quadruple with the operator at the top of the stack and adds it to the queue if it matches the given
    // operator's precedence. If not, it does nothing. It must be an operator with one operand. If the operand's type
    // does not match, an error is thrown.
    public func generateOneOperandExpQuadruple(op: LangOperator, line: Int, col: Int) {
        guard let top = operatorStack.top, op.precedence() == top.precedence() else {
            return
        }
        // It is guaranteed that stacks contain elements.
        let operand = operandStack.pop()!
        let operandType = typeStack.pop()!
        let topOperator = operatorStack.pop()!
        let resultType = ExpressionTypeTable.getDataType(op: topOperator, type1: operandType, type2: operandType)

        guard resultType != .errType else {
            let expectedType: DataType
            if topOperator == .posOp || topOperator == .negOp {
                expectedType = .intType
            } else {
                expectedType = .boolType
            }
            SemanticError.handle(.typeMismatch(expected: expectedType, received: operandType), line: line, col: col)
            return
        }
        let result = tempAllocators.top!.getNext(resultType)
        instructionQueue.push(
                Quadruple(
                        instruction: langOperatorToVMOperator(op: topOperator),
                        first: operand,
                        second: nil,
                        res: result))
        operandStack.push(result)
        typeStack.push(resultType)
        tempAllocators.top!.recycle(operand)
    }

    // Generates quadruples necessary for the start of an if expression. The operand at the top of the stack must be of
    // type bool or an error will be thrown.
    public func generateIfStart(line: Int, col: Int) {
        // Stacks are guaranteed to have values.
        let expressionType = typeStack.pop()!
        guard case DataType.boolType = expressionType else {
            SemanticError.handle(.typeMismatch(expected: .boolType, received: expressionType), line: line, col: col)
            return
        }
        let result = operandStack.pop()!
        instructionQueue.push(Quadruple(instruction: .goToFalse, first: result, second: nil, res: nil))
        jumpStack.push(instructionQueue.nextInstruction - 1)
    }

    // Generates quadruples necessary for the start of the else part of an if expression.
    public func generateElseStart() {
        instructionQueue.push(Quadruple(instruction: .goTo, first: nil, second: nil, res: nil))
        // Stack is guaranteed to contain a value.
        let falseJump = jumpStack.pop()!
        jumpStack.push(instructionQueue.nextInstruction - 1)
        instructionQueue.fillResult(at: falseJump, result: instructionQueue.nextInstruction)
    }

    // Generates quadruples necessary for the end of an if expression. If intermediate expressions of the if-else
    // expression are not of the same type, an error is thrown.
    public func generateIfEnd(line: Int, col: Int) {
        // Stacks are guaranteed to contain values.
        let elseResult = operandStack.pop()!
        let elseType = typeStack.pop()!
        let thenResult = operandStack.top!
        let thenType = typeStack.top!
        guard thenType == elseType else {
            SemanticError.handle(.typeMismatch(expected: thenType, received: elseType), line: line, col: col)
            return // Dummy return.
        }
        instructionQueue.push(Quadruple(instruction: .assign, first: elseResult, second: nil, res: thenResult))
        tempAllocators.top!.recycle(elseResult)

        let endJump = jumpStack.pop()!
        instructionQueue.fillResult(at: endJump, result: instructionQueue.nextInstruction)
    }

    public func printQueue() {
        for i in 0 ..< instructionQueue.count {
            print("\(i). \(String(describing: instructionQueue[i]))")
        }
    }
}

// Utility methods
extension CodeGenerator {
    // Maps from a LangOperator to a VMOperator.
    private func langOperatorToVMOperator(op: LangOperator) -> VMOperator {
        switch op {
        case .plusOp:
            return .add
        case .minusOp:
            return .subtract
        case .multOp:
            return .multiply
        case .divOp:
            return .divide
        case .consOp:
            return .cons
        case .appendOp:
            return .append
        case .eqOp:
            return .equal
        case .notEqOp:
            return .notEqual
        case .gThanOp:
            return .greaterThan
        case .lThanOp:
            return .lessThan
        case .gEqOp:
            return .greaterEqual
        case .lEqOp:
            return .lessEqual
        case .orOp:
            return .or
        case .andOp:
            return .and
        case .posOp:
            return .positive
        case .negOp:
            return .negative
        case .notOp:
            return .not
        case .assgOp:
            return .assign
        default:
            SemanticError.handle(.internalError)
            return .placeholder // Dummy return.
        }
    }
}

