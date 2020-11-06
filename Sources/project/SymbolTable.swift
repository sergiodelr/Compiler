//
// Created by sergio on 08/10/2020.
//

import Foundation
import VirtualMachineLib

// Symbol table containing relevant information about variables and functions. Each entry optionally contains a
// reference to its own symbol table and to its parent table.
public class SymbolTable: CustomDebugStringConvertible {
    public enum SymbolKind {
        case constKind
        case funcKind
        case noKind
    }

    // An entry in the symbol table.
    public struct Entry: CustomDebugStringConvertible {
        public var name: String = ""
        public var dataType: DataType = .noneType
        public var kind: SymbolKind = .noKind
        public var address: Int? = nil

        public init(name: String, dataType: DataType, kind: SymbolKind, address: Int?) {
            self.name = name
            self.dataType = dataType
            self.kind = kind
            self.address = address
        }

        public var debugDescription: String { return "n: \(name), t: \(dataType), k: \(kind)" }
    }

    // Private
    private var table: [String: Entry]

    // Public
    public var parent: SymbolTable?

    public var entries: [SymbolTable.Entry] {
        return Array(table.values)
    }

    public init( parent: SymbolTable? = nil) {
        table = [:]
        self.parent = parent
    }

    // Subscript access to the symbol table.
    public subscript(name: String) -> Entry? {
        get {
            return table[name]
        }
        set {
            table[name] = newValue
            print(String(reflecting: self))
        }
    }

    // Looks for a name in the table and returns whether it finds it or not.
    public func find(_ name: String) -> Bool {
        return table[name] != nil
    }

    public var debugDescription: String { return "Symbol Table" + "\n" + String(reflecting: table) }
}
