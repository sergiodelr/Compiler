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
    // Maps from a string with a literal value to its literal value entry.
    private var literalDict: [String: ValueEntry]
    // Stack for operators in expressions
    private var operatorStack: Stack<LangOperator>
    // Stack for operands in expressions. Contains the operands' virtual address.
    private var operandStack: Stack<Int>
    // Stack for operand types.
    private var typeStack: Stack<DataType>
    // Jump stack for conditional statements.
    private var jumpStack: Stack<Int>
    // Function stack.
    private var funcStack: Stack<FuncValueEntry>

    // Searches for a symbol in the current table and in parent tables and returns the entry if found.
    private func find(name: String) -> SymbolTable.Entry? {
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

    // Imports the symbol in the given entry to the current table. Returns the entry's address.
    private func importSymbol(entry: SymbolTable.Entry) -> Int {
        guard !symbolTable.find(entry.name) else {
            SemanticError.handle(.symbolAmbiguity(symbol: entry.name))
            return 0 // Dummy return.
        }

        let address = localAllocators.top!.getNext(entry.dataType)
        symbolTable[entry.name] = SymbolTable.Entry(
                name: entry.name,
                dataType: entry.dataType,
                kind: entry.kind,
                address: address)
        return address
    }

    // Public
    public init() {
        instructionQueue = InstructionQueue()
        operatorStack = Stack<LangOperator>()
        operandStack = Stack<Int>()
        typeStack = Stack<DataType>()
        jumpStack = Stack<Int>()
        funcStack = Stack<FuncValueEntry>()
        globalTable = SymbolTable()
        symbolTable = globalTable
        literalDict = [String: ValueEntry]()

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

        // Would be better with a guard case, but it is not possible.
        if case DataType.genType = type {
            SemanticError.handle(.genTypeNotSupported, line: line, col: col)
        } else {
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
        let value = valueFromString(literal, type: type)
        if let literalValueEntry = literalDict[literal] {
            operandStack.push(literalValueEntry.address)
        } else {
            let nextAddress = literalAllocator.getNext(type)
            literalDict[literal] = LiteralValueEntry(address: nextAddress, value: value, type: type)
            operandStack.push(nextAddress)
        }
        typeStack.push(type)
    }

    // Pushes a lambda, given its value entry, to the operand stack and its type to the type stack.
    public func pushLambda(_ funcValueEntry: FuncValueEntry) {
        // Store lambda literal in dictionary. Names won't collide.
        literalDict["lambda\(funcValueEntry.address)"] = funcValueEntry
        operandStack.push(funcValueEntry.address)
        typeStack.push(.funcType(paramTypes: funcValueEntry.paramTypes, returnType: funcValueEntry.returnType))
    }

    // Pushes a list
    public func pushList() {
        if let listValueEntry = literalDict["[]"] {
            operandStack.push(listValueEntry.address)
        } else {
            let listCellAddress = literalAllocator.getNext(.listType(innerType: .noneType))
            literalDict["[]"] = ListValueEntry(address: listCellAddress, value: nil)
            operandStack.push(listCellAddress)
        }
        typeStack.push(.listType(innerType: .noneType))
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
            print(leftOperand)
            print(rightOperand)
            print(topOperator)
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
    // operator's precedence for right associative operators. If not, it does nothing. It must be an operator with two
    //  operands. If the operands' types do not match, an error is thrown.
    public func generateTwoOperandsExpQuadrupleRight(op: LangOperator, line: Int, col: Int) {
        while let top = operatorStack.top, op.precedence() == top.precedence() {
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

            let result = tempAllocators.top!.getNext(resultType)
            instructionQueue.push(
                    Quadruple(
                            instruction: langOperatorToVMOperator(op: topOperator),
                            first: leftOperand,
                            second: rightOperand,
                            res: result))
            operandStack.push(result)
            typeStack.push(resultType)

            tempAllocators.top!.recycle(leftOperand)
            tempAllocators.top!.recycle(rightOperand)
        }
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
        // Copy result of then expression to a temp. Pop actual result from stack.
        // Stacks are guaranteed to contain values.
        let thenResult = operandStack.pop()!
        let thenType = typeStack.top!
        let tempResult = tempAllocators.top!.getNext(thenType)
        instructionQueue.push(Quadruple(instruction: .assign, first: thenResult, second: nil, res: tempResult))
        operandStack.push(tempResult)
        tempAllocators.top!.recycle(thenResult)

        // Goto statement to skip else expression.
        instructionQueue.push(Quadruple(instruction: .goTo, first: nil, second: nil, res: nil))
        let falseJump = jumpStack.pop()!
        jumpStack.push(instructionQueue.nextInstruction - 1)
        instructionQueue.fillResult(at: falseJump, result: instructionQueue.nextInstruction)
    }

    // Generates quadruples necessary for the end of an if expression. If intermediate expressions of the if-else
    // expression are not of the same type, an error is thrown.
    public func generateIfEnd(line: Int, col: Int) {
        // Overwrite result from then expression.
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

    // Creates a lambda literal. Generates quadruples necessary for function starts. Imports symbols from context to
    // current table.
    public func generateFuncStart(type: DataType) {
        // Create lambda literal.
        // Stacks are guaranteed to contain values.
        let lambdaAddress = literalAllocator.getNext(.funcType(paramTypes: [], returnType: .noneType))

        // TODO: Prevent const where lambda will be assigned from being imported.
        // Import local symbols from context.
        // Table is guaranteed to have a parent.
        let tempTable = symbolTable.parent!
        var newAddress: Int
        if tempTable !== globalTable {
            for entry in tempTable.entries {
                newAddress = importSymbol(entry: entry)
                instructionQueue.push(
                        Quadruple(
                                instruction: .importCon,
                                first: lambdaAddress,
                                second: entry.address,
                                res: newAddress))
            }
        }
        // Generate goto quadruple to jump function body.
        instructionQueue.push(Quadruple(instruction: .goTo, first: nil, second: nil, res: nil))
        jumpStack.push(instructionQueue.nextInstruction - 1)

        let lambdaStart = instructionQueue.nextInstruction
        let valueEntry = FuncValueEntry(address: lambdaAddress, value: lambdaStart, type: type)
        funcStack.push(valueEntry)
    }

    // Generates quadruples necessary for function ends.
    public func generateFuncEnd(line: Int, col: Int) {
        // Stacks are guaranteed to contain values.
        let returnVal = operandStack.pop()!
        let returnType = typeStack.pop()!
        let funcStartIndex = jumpStack.pop()!
        var funcValueEntry = funcStack.pop()!
        guard returnType == funcValueEntry.returnType else {
            SemanticError.handle(
                    .typeMismatch(expected: funcValueEntry.returnType, received: returnType),
                    line: line,
                    col: col)
            return // Dummy return.
        }
        instructionQueue.push(Quadruple(instruction: .ret, first: nil, second: nil, res: returnVal))
        instructionQueue.fillResult(at: funcStartIndex, result: instructionQueue.nextInstruction)

        // Finish filling lambda properties.
        funcValueEntry.tempCount[.intType] = tempAllocators.top!.maxIntCount
        funcValueEntry.tempCount[.floatType] = tempAllocators.top!.maxFloatCount
        funcValueEntry.tempCount[.boolType] = tempAllocators.top!.maxBoolCount
        funcValueEntry.tempCount[.charType] = tempAllocators.top!.maxCharCount
        funcValueEntry.tempCount[.funcType(paramTypes: [], returnType: .noneType)] = tempAllocators.top!.maxFuncCount
        funcValueEntry.tempCount[.listType(innerType: .noneType)] = tempAllocators.top!.maxListCount

        funcValueEntry.constCount[.intType] = localAllocators.top!.maxIntCount
        funcValueEntry.constCount[.floatType] = localAllocators.top!.maxFloatCount
        funcValueEntry.constCount[.boolType] = localAllocators.top!.maxBoolCount
        funcValueEntry.constCount[.charType] = localAllocators.top!.maxCharCount
        funcValueEntry.constCount[.funcType(paramTypes: [], returnType: .noneType)] = localAllocators.top!.maxFuncCount
        funcValueEntry.constCount[.listType(innerType: .noneType)] = localAllocators.top!.maxListCount
        pushLambda(funcValueEntry)
    }

    // Generates quadruples necessary for function calls. If operand on top of the stack is not a function, an error is
    // thrown.
    public func generateFuncCallStart(line: Int, col: Int) {
        // Check that operand is a function.
        // Stacks are guaranteed to contain values.
        let funcOp = operandStack.top!
        let funcType = typeStack.top!
        guard case let DataType.funcType(paramTypes, returnType) = funcType else {
            SemanticError.handle(.invalidFuncCall, line: line, col: col)
            return // Dummy return.
        }
        instructionQueue.push(Quadruple(instruction: .alloc, first: nil, second: nil, res: funcOp))
        print("fcs")
    }

    // Generates quadruples necessary for sending arguments to function calls. If argument count or type does not match
    // an error is thrown.
    public func generateArgument(atPosition pos: Int, line: Int, col: Int) {
        // Stacks are guaranteed to contain values.
        let arg = operandStack.pop()!
        let argType = typeStack.pop()!
        let funcType = typeStack.top!
        // Guard case will always match.
        guard case DataType.funcType(let paramTypes, _) = funcType else {
            SemanticError.handle(.internalError)
            return // Dummy return.
        }
        // Check that arg position is not greater than argument count.
        guard pos <= paramTypes.count else {
            SemanticError.handle(.invalidArgCount(expected: paramTypes.count, received: pos), line: line, col: col)
            return // Dummy return.
        }
        // Check that types match.
        // TODO: Allow casting between float and int.
        guard paramTypes[pos] == argType else {
            SemanticError.handle(.typeMismatch(expected: paramTypes[pos], received: argType), line: line, col: col)
            return // Dummy return.
        }
        instructionQueue.push(Quadruple(instruction: .arg, first: arg, second: nil, res: pos))
        print("arg")
    }

    // Generate quadruples necessary to end a func call. If argument count does not match, an error is thrown.
    public func generateFuncCallEnd(argCount: Int, line: Int, col: Int) {
        // Stacks are guaranteed to contain values.
        let funcOp = operandStack.pop()!
        let funcType = typeStack.pop()!
        // Guard case will always match.
        guard case let DataType.funcType(paramTypes, returnType) = funcType else {
            SemanticError.handle(.internalError)
            return // Dummy return.
        }
        // Check that argCount is equal to expected count.
        guard argCount == paramTypes.count else {
            SemanticError.handle(.invalidArgCount(expected: paramTypes.count, received: argCount), line: line, col: col)
            return // Dummy return.
        }
        instructionQueue.push(Quadruple(instruction: .call, first: nil, second: nil, res: funcOp))

        // Receive return value and push it to stack.
        let funcResult = tempAllocators.top!.getNext(returnType)
        instructionQueue.push(Quadruple(instruction: .receiveRes, first: nil, second: nil, res: funcResult))
        operandStack.push(funcResult)
        typeStack.push(returnType)
    }

    // Generates quadruples necessary for read.
    public func generateRead(type: DataType, line: Int, col: Int) {
        let readAddress = tempAllocators.top!.getNext(type)
        instructionQueue.push(Quadruple(instruction: .read, first: nil, second: nil, res: readAddress))
        operandStack.push(readAddress)
        typeStack.push(type)
    }

    // Generates quadruples necessary for print.
    public func generatePrint() {
        // Stacks are guaranteed to contain values.
        let printAddress = operandStack.pop()!
        typeStack.pop()!
        instructionQueue.push(Quadruple(instruction: .print, first: nil, second: nil, res: printAddress))
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

    // Builds a value entry.
    private func valueFromString(_ stringValue: String, type: DataType) -> Any {
        // stringValue is guaranteed to be valid.
        switch type {
        case .intType:
            return Int(stringValue)!
        case .floatType:
            return Float(stringValue)!
        case .charType:
            var value = stringValue
            value.removeFirst()
            value.popLast()
            return value
        case .boolType:
            return stringValue == "true"
        default:
            SemanticError.handle(.internalError)
            return 0 // Dummy return.
        }
    }
}

