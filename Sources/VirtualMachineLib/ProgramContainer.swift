//
// Created by sergio on 10/11/2020.
//

import Foundation

// Serializes the instruction queue and other structures necessary to run a program. Encodes and decodes them, as
// well as writing and reading them from files.
public class ProgramContainer: Codable {
    public let instructionQueue: InstructionQueue

    var intLiterals: [Int: Int]
    var floatLiterals: [Int: Float]
    var charLiterals: [Int: String]
    var boolLiterals: [Int: Bool]
    var funcLiterals: [Int: FuncValue]
    var listLiterals: [Int: ListValue]

    public class func create(fromFileAtPath path: String) -> ProgramContainer? {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let decodedData = try? JSONDecoder().decode(ProgramContainer.self, from: data)
        return decodedData
    }

    public init(instructionQueue: InstructionQueue, valueEntries: [ValueEntry]) throws {
        self.instructionQueue = instructionQueue

        intLiterals = [Int: Int]()
        floatLiterals = [Int: Float]()
        charLiterals = [Int: String]()
        boolLiterals = [Int: Bool]()
        funcLiterals = [Int: FuncValue]()
        listLiterals = [Int: ListValue]()

        for entry in valueEntries {
            switch entry.type {
            case .intType:
                intLiterals[entry.address] = entry.value as! Int
            case .floatType:
                floatLiterals[entry.address] = entry.value as! Float
            case .charType:
                charLiterals[entry.address] = entry.value as! String
            case .boolType:
                boolLiterals[entry.address] = entry.value as! Bool
            case .listType:
                listLiterals[entry.address] = ListValue(fromValueEntry: entry as! ListValueEntry)
            case .funcType:
                funcLiterals[entry.address] = FuncValue(fromValueEntry: entry as! FuncValueEntry)
            default:
                throw SavingError.unsupportedTypes
            }
        }
    }

    // Saves itself to the specified path.
    public func save(toFileAtPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: url)
        } catch EncodingError.invalidValue {
            throw SavingError.invalidEncodingValue
        } catch {
            throw SavingError.couldNotSave
        }
    }
}
