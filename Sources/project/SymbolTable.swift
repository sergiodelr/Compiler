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
        public var assigned: Bool = false

        public init(name: String, dataType: DataType, kind: SymbolKind, address: Int?, assigned: Bool = false) {
            self.name = name
            self.dataType = dataType
            self.kind = kind
            self.address = address
            self.assigned = assigned
        }

        public var debugDescription: String { return "n: \(name), t: \(dataType), a: \(address)" }
    }

    // Private
    private var table: [String: Entry]
    private var addressToName: [Int: String]
    // Public
    public var parent: SymbolTable?

    public var entries: [SymbolTable.Entry] {
        return Array(table.values)
    }

    public init( parent: SymbolTable? = nil) {
        table = [:]
        addressToName = [:]
        self.parent = parent
    }

    // Subscript access to the symbol table.
    public subscript(name: String) -> Entry? {
        get {
            return table[name]
        }
        set {
            table[name] = newValue
            if let entry = newValue {
                addressToName[entry.address!] = name
            }

            print(String(reflecting: self))
        }
    }

    // Address-based subscript access.
    public subscript(address: Int) -> Entry? {
        get {
            if let name = addressToName[address] {
                return table[name]
            }
            return nil
        }
        set {
            if let name = addressToName[address] {
                table[name] = newValue
            }
        }
    }

    // Looks for a name in the table and returns whether it finds it or not.
    public func find(_ name: String) -> Bool {
        return table[name] != nil
    }

    public var debugDescription: String { return "Symbol Table" + "\n" + String(reflecting: table) }
}
