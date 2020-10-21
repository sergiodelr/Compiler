/*-------------------------------------------------------------------------
    Compiler Generator Coco/R,
    Copyright (c) 1990, 2004 Hanspeter Moessenboeck, University of Linz
    extended by M. Loeberbauer & A. Woess, Univ. of Linz
    with improvements by Pat Terry, Rhodes University
    Swift port by Michael Griebling, 2015-2017

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2, or (at your option) any
    later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    As an exception, it is allowed to write an extension of Coco/R that is
    used as a plugin in non-free software.

    If not otherwise stated, any source code generated by Coco/R (other than
    Coco/R itself) does not fall under the GNU General Public License.

    NOTE: The code below has been automatically generated from the
    Parser.frame, Scanner.frame and Coco.atg files.  DO NOT EDIT HERE.
-------------------------------------------------------------------------*/

import Foundation
import VirtualMachineLib

public class Parser {
    public let _EOF = 0
    public let _ID = 1
    public let _INTCONS = 2
    public let _FLOATCONS = 3
    public let _CHARCONS = 4
    public let _GENT = 5
    public let _LET = 6
    public let _IN = 7
    public let _FOR = 8
    public let _OTHERWISE = 9
    public let _IFT = 10
    public let _THEN = 11
    public let _ELSE = 12
    public let _DO = 13
    public let _MAIN = 14
    public let _LAMBDA = 15
    public let _READ = 16
    public let _PRINT = 17
    public let _TRUE = 18
    public let _FALSE = 19
    public let _INT = 20
    public let _FLOAT = 21
    public let _CHAR = 22
    public let _BOOL = 23
    public let maxT = 47

    static let _T = true
    static let _x = false
    static let minErrDist = 2
    let minErrDist: Int = Parser.minErrDist

    public var scanner: Scanner
    public var errors: Errors

    public var t: Token             // last recognized token
    public var la: Token            // lookahead token
    var errDist = Parser.minErrDist

    // MARK: Custom properties
    var globalTable: SymbolTable
    // Current symbol table
    var symbolTable: SymbolTable
    // Instruction queue
    var instructionQueue: InstructionQueue
    // Stack for operators in expressions
    var operatorStack: Stack<LangOperator>
    // Stack for operands in expressions. Contains the operands' virtual address.
    var operandStack: Stack<Int>

    // MARK: Edited method
    public init(scanner: Scanner) {
        self.scanner = scanner

        globalTable = SymbolTable()
        instructionQueue = InstructionQueue()
        operatorStack = Stack<LangOperator>()
        operandStack = Stack<Int>()

        symbolTable = globalTable
        errors = Errors()
        t = Token()
        la = t
    }

    func SynErr(_ n: Int) {
        if errDist >= minErrDist {
            errors.SynErr(la.line, col: la.col, n: n)
        }
        errDist = 0
    }

    public func SemErr(_ msg: String) {
        if errDist >= minErrDist {
            errors.SemErr(t.line, col: t.col, s: msg)
        }
        errDist = 0
    }

    func Get() {
        while true {
            t = la
            la = scanner.Scan()
            if la.kind <= maxT {
                errDist += 1; break
            }

            la = t
        }
    }

    func Expect(_ n: Int) {
        if la.kind == n {
            Get()
        } else {
            SynErr(n)
        }
    }

    func StartOf(_ s: Int) -> Bool {
        return set(s, la.kind)
    }

    func ExpectWeak(_ n: Int, _ follow: Int) {
        if la.kind == n {
            Get()
        } else {
            SynErr(n)
            while !StartOf(follow) {
                Get()
            }
        }
    }

    func WeakSeparator(_ n: Int, _ syFol: Int, _ repFol: Int) -> Bool {
        var kind = la.kind
        if kind == n {
            Get(); return true
        } else if StartOf(repFol) {
            return false
        } else {
            SynErr(n)
            while !(set(syFol, kind) || set(repFol, kind) || set(0, kind)) {
                Get()
                kind = la.kind
            }
            return StartOf(syFol)
        }
    }

    func Comp() {
        Program()
    }

    // MARK: Edited method.
    func Program() {
        symbolTable = globalTable
        while la.kind == _LET {
            Definition()
        }
        Main()
    }

    // MARK: Edited method.
    // Adds definition to Symbol Table or marks an error.
    func Definition() {
        Expect(_LET)
        Expect(_ID)

        var symbolEntry = SymbolTable.Entry()
        symbolEntry.name = getIdName()

        if la.kind == 24 /* ":" */ {
            ConstDef(&symbolEntry)
        } else if la.kind == 26 /* "(" */ {
            symbolEntry.kind = .funcKind

            FuncDef(&symbolEntry)
        } else {
            SynErr(48)
        }
    }

    // MARK: Edited method.
    // Creates a symbol table for its local constants.
    func Main() {
        Expect(_MAIN)
        Expect(25 /* "=" */)

        let mainTable = SymbolTable(parent: symbolTable)
        symbolTable = mainTable

        Expect(_DO)
        while la.kind == _LET || la.kind == _PRINT {
            if la.kind == _LET {
                ConstDefInter()
            } else {
                Print()
            }
        }
        symbolTable = symbolTable.parent!
    }

    // MARK: Edited method
    // Receives a symbolEntry and sets its data type, kind, and child table. If entry is of kind lambda, its parameters
    // will be added to its child table (in another method). Adds the symbolEntry to the symbol table.
    func ConstDef(_ symbolEntry: inout SymbolTable.Entry) {
        Expect(24 /* ":" */)

        setTypeKind(&symbolEntry)
        symbolTable[symbolEntry.name] = symbolEntry

        Expect(25 /* "=" */)
        if StartOf(1) {
            Expression()
            // TODO: check expression type. Delete Expression() call above.
//			let expressionType = Expression()
//			guard expressionType == symbolEntry.dataType else {
//				// TODO: Type mismatch.
//                throw SemanticError.typeMismatch
//			}
        } else if la.kind == _READ {
            //TODO: Don't allow read statement in global scope.
            Get()
            Expect(26 /* "(" */)
            Expect(27 /* ")" */)
        } else {
            SynErr(49)
        }
    }

    // MARK: Edited method.
    // Sets the symbolEntry's type and kind. It calls FuncBody(), which will create a symbol table for each pattern
    // matching case.
    func FuncDef(_ symbolEntry: inout SymbolTable.Entry) {
        Expect(26 /* "(" */)
        let paramTypes = ParamList()
        Expect(27 /* ")" */)
        Expect(24 /* ":" */)
        let returnType = Type()
        symbolEntry.dataType = .funcType(paramTypes: paramTypes, returnType: returnType)
        symbolTable[symbolEntry.name] = symbolEntry

        Expect(25 /* "=" */)
        Expect(28 /* "{" */)
        FuncBody(symbolEntry.dataType)
        Expect(29 /* "}" */)
    }

    // MARK: Edited method.
    // Returns the parsed data type.
    @discardableResult
    func Type() -> DataType {
        var res = DataType.noneType
        if StartOf(2) {
            // Simple type.
            res = SimpleType()
        } else if la.kind == 26 /* "(" */ {
            // Function type.
            var paramTypes = [DataType]()
            Get()
            paramTypes.append(Type()) // Reads type from input.
            while la.kind == 30 /* "," */ {
                Get()
                paramTypes.append(Type()) // Reads type from input.
            }
            Expect(27 /* ")" */)
            Expect(24 /* ":" */)
            let returnType = Type()
            res = .funcType(paramTypes: paramTypes, returnType: returnType)
        } else if la.kind == 31 /* "[" */ {
            // List type.
            Get()
            res = .listType(innerType: Type())
            Expect(32 /* "]" */)
        } else {
            res = .errType
            SynErr(50)
        }
        return res
    }

    // MARK: Edited method.
    // Returns the expression's data type.
    @discardableResult
    func Expression() -> DataType {
        var res = DataType.noneType
        if la.kind == _LAMBDA {
            // Set current symbol table to lambda symbol table.
            let lambdaTable = SymbolTable(parent: symbolTable)
            symbolTable = lambdaTable
            res = LambdaExp()
            // Reset current symbol table.
            symbolTable = symbolTable.parent! // Table's parent is set above.
        } else if StartOf(3) {
            res = SimpleExp()
        } else {
            res = .errType
            SynErr(51)
        }
        return res
    }

    // MARK: Edited method.
    // Returns an array with the parameter types.
    func ParamList() -> [DataType] {
        var res = [DataType]()
        res.append(Type()) // Reads type from input.
        while la.kind == 30 /* "," */ {
            Get()
            res.append(Type()) // Reads type from input.
        }
        return res
    }

    // MARK: Edited method
    // Creates a symbol table for each pattern and sets it as the current one.
    func FuncBody(_ funcType: DataType) {
        var caseTable = SymbolTable(parent: symbolTable)
        symbolTable = caseTable
        Case(funcType)
        symbolTable = symbolTable.parent! // Parent was just set above
        while la.kind == _FOR {
            caseTable = SymbolTable(parent: symbolTable)
            symbolTable = caseTable
            Case(funcType)
            symbolTable = symbolTable.parent! // Parent was just set above
        }
    }

    // MARK: Edited method
    // Returns a simple data type.
    func SimpleType() -> DataType {
        var genId: Character? = nil
        if la.kind == _INT {
            Get()
        } else if la.kind == _FLOAT {
            Get()
        } else if la.kind == _CHAR {
            Get()
        } else if la.kind == _BOOL {
            Get()
        } else if la.kind == _GENT {
            Get()
            genId = t.val[0] // Generic IDs must have just one letter.
        } else {
            SynErr(52)
        }
        return dataTypeFromSimpleType(t.kind, genericId: genId)
    }

    // MARK: Edited method.
    // Receives the function data type. Used to add local constants to symbol table.
    func Case(_ funcType: DataType) {
        Expect(_FOR)
        // If case statement is used to extract parameter and return types. It is guaranteed that pattern will always
        // have a match.
        if case let DataType.funcType(paramTypes, returnType) = funcType {
            PatternList(paramTypes)
            Expect(25 /* "=" */)
            if la.kind == _LET {
                ConstList()
            }
            Expression()
        } else {
            SemanticError.handle(.internalError, line: t.line, col: t.col)
        }
    }

    // MARK: Edited method.
    // Receives the parameter types. Matches each pattern with its type.
    func PatternList(_ paramTypes: [DataType]) {
        // TODO: finish pattern matching.
        Pattern(paramTypes[0])
        var patCount = 1
        while la.kind == 30 /* "," */ {
            Get()
            Pattern(paramTypes[patCount])
            patCount += 1
        }
    }

    func ConstList() {
        ConstDefInter()
        while la.kind == 30 /* "," */ {
            Get()
            ConstDefInter()
        }
        Expect(_IN)
    }

    // MARK: Edited method.
    // Receives a data type and matches the pattern. If pattern is an id, it adds it to the symbol table.
    func Pattern(_ patternType: DataType) {
        if la.kind == 42 /* "-" */ || la.kind == _INTCONS || la.kind == _FLOATCONS {
            if la.kind == 42 /* "-" */ {
                Get()
            }
            if la.kind == _INTCONS {
                Get()
            } else if la.kind == _FLOATCONS {
                Get()
            } else {
                SynErr(53)
            }
        } else if la.kind == _CHARCONS {
            Get()
        } else if la.kind == _ID {
            Get()
            let firstId = t.val
            var secondId: String? = nil

            if la.kind == 24 /* ":" */ {
                Get()
                Expect(_ID)
                secondId = t.val
            }

            switch patternType {
            case let .listType(innerType):
                if let secondId = secondId {
                    // If it is a list type and pattern is "id1:id2", add both ids to symbol table if they are not "_".
                    if firstId != "_" {
                        symbolTable[firstId] = SymbolTable.Entry(
                                name: firstId,
                                dataType: innerType,
                                kind: .constKind,
                                address: nil)
                    }
                    if secondId != "_" {
                        symbolTable[secondId] = SymbolTable.Entry(
                                name: secondId,
                                dataType: patternType,
                                kind: .constKind,
                                address: nil)
                    }
                } else {
                    // If there is only one id, then add it to the symbol table with patternType if it is not "_".
                    if firstId != "_" {
                        symbolTable[firstId] = SymbolTable.Entry(
                                name: firstId,
                                dataType: patternType,
                                kind: .constKind,
                                address: nil)
                    }
                }
            default:
                if let secondId = secondId {
                    // If patternType != list type and there are two ids, throw an error.
                    SemanticError.handle(
                            .typeMismatch(expected: patternType, received: .listType(innerType: patternType)),
                            line: t.line,
                            col: t.col)
                } else {
                    // Else add entry normally to table.
                    if firstId != "_" {
                        symbolTable[firstId] = SymbolTable.Entry(
                                name: firstId,
                                dataType: patternType,
                                kind: .constKind,
                                address: nil)
                    }
                }
            }

        } else if la.kind == 31 /* "[" */ {
            Get()
            Expect(32 /* "]" */)
        } else {
            SynErr(53)
        }
    }

    // Creates a symbol entry and sets its name, data type, kind, and child table. If entry is of kind lambda, its
    // parameters will be added to its child table (in another method). Adds the symbolEntry to the symbol table.
    func ConstDefInter() {
        Expect(_LET)
        Expect(_ID)

        var symbolEntry = SymbolTable.Entry()
        symbolEntry.name = getIdName()

        Expect(24 /* ":" */)

        setTypeKind(&symbolEntry)
        symbolTable[symbolEntry.name] = symbolEntry

        Expect(25 /* "=" */)
        if StartOf(1) {
            Expression()
        } else if la.kind == _READ {
            // TODO: Only allow read in main function.
            Get()
            Expect(26 /* "(" */)
            Expect(27 /* ")" */)
        } else {
            SynErr(54)
        }
    }

    // MARK: Edited method.
    // Creates a Symbol Entry for each parameter in the lambda and stores it in the current symbol table or marks error.
    // Returns lambda's type.
    func LambdaExp() -> DataType {
        Expect(_LAMBDA)
        var paramTypes = [DataType]()
        Expect(26 /* "(" */)
        if la.kind == _ID {
            Get()
            var symbolEntry = SymbolTable.Entry()
            symbolEntry.name = getIdName()

            Expect(24 /* ":" */)
            // Parses type
            setTypeKind(&symbolEntry)
            symbolTable[symbolEntry.name] = symbolEntry
            paramTypes.append(symbolEntry.dataType)
            while la.kind == 30 /* "," */ {
                symbolEntry = SymbolTable.Entry()
                Get()
                Expect(_ID)
                symbolEntry.name = getIdName()

                Expect(24 /* ":" */)
                // Parses type
                setTypeKind(&symbolEntry)
                symbolTable[symbolEntry.name] = symbolEntry
                paramTypes.append(symbolEntry.dataType)
            }
        }
        Expect(27 /* ")" */)
        Expect(24 /* ":" */)
        let returnType = Type()
        let res = DataType.funcType(paramTypes: paramTypes, returnType: returnType)
        Expect(28 /* "{" */)
        Expression()
        // TODO: check type. Delete expression call above.
//        let expressionType = Expression()
//        guard expressionType == res else {
//            // TODO: Type mismatch.
//            throw SemanticError.typeMismatch
//        }
        Expect(29 /* "}" */)
        return res
    }

    // MARK: Edited method
    @discardableResult
    func SimpleExp() -> DataType {
        if la.kind == _IFT {
            IfExp()
        } else if StartOf(4) {
            Exp()
        } else {
            SynErr(55)
        }
        return .noneType
    }

    func IfExp() {
        Expect(_IFT)
        Exp()
        Expect(_THEN)
        SimpleExp()
        Expect(_ELSE)
        SimpleExp()
    }

    func Exp() {
        AndExp()
        while la.kind == 33 /* "|" */ {
            Get()
            AndExp()
        }
    }

    func AndExp() {
        LogicalExp()
        while la.kind == 34 /* "&" */ {
            Get()
            LogicalExp()
        }
    }

    func LogicalExp() {
        MathExp()
        while StartOf(5) {
            switch la.kind {
            case 35 /* "==" */:
                Get()
            case 36 /* "!=" */:
                Get()
            case 37 /* "<" */:
                Get()
            case 38 /* "<=" */:
                Get()
            case 39 /* ">" */:
                Get()
            case 40 /* ">=" */:
                Get()
            default:
                break
            }
            MathExp()
        }
    }

    func MathExp() {
        Term()
        while la.kind == 41 /* "+" */ || la.kind == 42 /* "-" */ {
            if la.kind == 41 /* "+" */ {
                Get()
            } else {
                Get()
            }
            Term()
        }
    }

    func Term() {
        ListExp()
        while la.kind == 43 /* "*" */ || la.kind == 44 /* "/" */ {
            if la.kind == 43 /* "*" */ {
                Get()
            } else {
                Get()
            }
            ListExp()
        }
    }

    func ListExp() {
        Factor()
        while la.kind == 24 /* ":" */ || la.kind == 45 /* "++" */ {
            if la.kind == 24 /* ":" */ {
                Get()
            } else {
                Get()
            }
            Factor()
        }
    }

    func Factor() {
        if la.kind == 41 /* "+" */ || la.kind == 42 /* "-" */ || la.kind == 46 /* "!" */ {
            if la.kind == 41 /* "+" */ {
                Get()
            } else if la.kind == 42 /* "-" */ {
                Get()
            } else {
                Get()
            }
        }
        switch la.kind {
        case _INTCONS:
            Get()
        case _FLOATCONS:
            Get()
        case _CHARCONS:
            Get()
        case _ID:
            Get()
            if la.kind == 26 /* "(" */ {
                Get()
                if StartOf(1) {
                    Expression()
                    while la.kind == 30 /* "," */ {
                        Get()
                        Expression()
                    }
                }
                Expect(27 /* ")" */)
            }
        case 31 /* "[" */:
            List()
        case 26 /* "(" */:
            Get()
            SimpleExp()
            Expect(27 /* ")" */)
        default: SynErr(56)
        }
    }

    func List() {
        Expect(31 /* "[" */)
        if StartOf(1) {
            Expression()
            while la.kind == 30 /* "," */ {
                Get()
                Expression()
            }
        }
        Expect(32 /* "]" */)
    }

    func Print() {
        Expect(_PRINT)
        Expect(26 /* "(" */)
        SimpleExp()
        Expect(27 /* ")" */)
    }


    public func Parse() {
        la = Token()
        la.val = ""
        Get()
        Comp()
        Expect(_EOF)

    }

    func set(_ x: Int, _ y: Int) -> Bool {
        return Parser._set[x][y]
    }

    static let _set: [[Bool]] = [
        [_T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x],
        [_x, _T, _T, _T, _T, _x, _x, _x, _x, _x, _T, _x, _x, _x, _x, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _x, _x, _x, _x, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _T, _x, _x, _x, _T, _x, _x],
        [_x, _x, _x, _x, _x, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _T, _T, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x],
        [_x, _T, _T, _T, _T, _x, _x, _x, _x, _x, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _x, _x, _x, _x, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _T, _x, _x, _x, _T, _x, _x],
        [_x, _T, _T, _T, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _x, _x, _x, _x, _T, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _T, _x, _x, _x, _T, _x, _x],
        [_x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _x, _T, _T, _T, _T, _T, _T, _x, _x, _x, _x, _x, _x, _x, _x]

    ]
} // end Parser


public class Errors {
    public var count = 0                                 // number of errors detected
    private let errorStream = stderr              // error messages go to this stream
    public var errMsgFormat = "-- line %i col %i: %@"    // 0=line, 1=column, 2=text

    func Write(_ s: String) {
        fputs(s, errorStream)
    }

    func WriteLine(_ format: String, line: Int, col: Int, s: String) {
        let str = "-- line \(line) col \(col): \(s)"
        WriteLine(str)
    }

    func WriteLine(_ s: String) {
        Write(s + "\n")
    }

    public func SynErr(_ line: Int, col: Int, n: Int) {
        var s: String
        switch n {
        case 0: s = "EOF expected"
        case 1: s = "ID expected"
        case 2: s = "INTCONS expected"
        case 3: s = "FLOATCONS expected"
        case 4: s = "CHARCONS expected"
        case 5: s = "GENT expected"
        case 6: s = "LET expected"
        case 7: s = "IN expected"
        case 8: s = "FOR expected"
        case 9: s = "OTHERWISE expected"
        case 10: s = "IFT expected"
        case 11: s = "THEN expected"
        case 12: s = "ELSE expected"
        case 13: s = "DO expected"
        case 14: s = "MAIN expected"
        case 15: s = "LAMBDA expected"
        case 16: s = "READ expected"
        case 17: s = "PRINT expected"
        case 18: s = "TRUE expected"
        case 19: s = "FALSE expected"
        case 20: s = "INT expected"
        case 21: s = "FLOAT expected"
        case 22: s = "CHAR expected"
        case 23: s = "BOOL expected"
        case 24: s = "\":\" expected"
        case 25: s = "\"=\" expected"
        case 26: s = "\"(\" expected"
        case 27: s = "\")\" expected"
        case 28: s = "\"{\" expected"
        case 29: s = "\"}\" expected"
        case 30: s = "\",\" expected"
        case 31: s = "\"[\" expected"
        case 32: s = "\"]\" expected"
        case 33: s = "\"|\" expected"
        case 34: s = "\"&\" expected"
        case 35: s = "\"==\" expected"
        case 36: s = "\"!=\" expected"
        case 37: s = "\"<\" expected"
        case 38: s = "\"<=\" expected"
        case 39: s = "\">\" expected"
        case 40: s = "\">=\" expected"
        case 41: s = "\"+\" expected"
        case 42: s = "\"-\" expected"
        case 43: s = "\"*\" expected"
        case 44: s = "\"/\" expected"
        case 45: s = "\"++\" expected"
        case 46: s = "\"!\" expected"
        case 47: s = "??? expected"
        case 48: s = "invalid Definition"
        case 49: s = "invalid ConstDef"
        case 50: s = "invalid Type"
        case 51: s = "invalid Expression"
        case 52: s = "invalid SimpleType"
        case 53: s = "invalid Pattern"
        case 54: s = "invalid ConstDefInter"
        case 55: s = "invalid SimpleExp"
        case 56: s = "invalid Factor"

        default: s = "error \(n)"
        }
        WriteLine(errMsgFormat, line: line, col: col, s: s)
        count += 1
    }

    public func SemErr(_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s);
        count += 1
    }

    public func SemErr(_ s: String) {
        WriteLine(s)
        count += 1
    }

    public func Warning(_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s)
    }

    public func Warning(_ s: String) {
        WriteLine(s)
    }
} // Errors

// MARK: Added extension.
// Utility functions
extension Parser {
    // Convenience function to convert simple type constants to DataTypes.
    func dataTypeFromSimpleType(_ simpleT: Int, genericId: Character? = nil) -> DataType {
        switch simpleT {
        case _INT:
            return .intType
        case _FLOAT:
            return .floatType
        case _BOOL:
            return .boolType
        case _CHAR:
            return .charType
        case _GENT:
            return .genType(identifier: genericId!) // If type is generic, then it must always have an ID.
        default:
            return .noneType
        }
    }

    // Checks whether the current token exists in the symbol table and returns it if it does. If not, it throws an
    // error.
    // This method must be called after a Get() or Expect().
    func getIdName() -> String {
        let name = t.val
        guard !symbolTable.find(name) else {
            SemanticError.handle(.multipleDeclaration(symbol: name), line: t.line, col: t.col)
            return "" // Dummy return. Execution will stop in handle method.
        }
        return name
    }

    // Sets the type and kind of the given symbol entry or throws an error. Contains Type(), which parses type token
    // from the input.
    func setTypeKind(_ symbolEntry: inout SymbolTable.Entry) {
        symbolEntry.dataType = Type()
        switch symbolEntry.dataType {
        case .funcType:
            symbolEntry.kind = .funcKind
        case .errType, .noneType:
            symbolEntry.kind = .noKind
                // TODO: Type error.
        default:
            symbolEntry.kind = .constKind
        }
    }
}
