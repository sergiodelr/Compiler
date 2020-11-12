//
// Created by sergio on 10/11/2020.
//

import Foundation

// Serializes the instruction queue and other structures necessary to run a program. Encodes and decodes them, as
// well as writing and reading them from files.
class ProgramContainer: Codable {
        let instructionQueue: InstructionQueue
    let intLiterals: [Int: Int]
    let floatLiterals: [Int: Float]
    let charLiterals: [Int: String]
    let boolLiterals: [Int: Bool]
    let funcLiterals: [Int: FuncValue]

    class func create(fromFileAtPath path: String) -> ProgramContainer? {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let decodedData = try? JSONDecoder().decode(ProgramContainer.self, from: data)
        return decodedData
    }

    init(instructionQueue: InstructionQueue, valueEntries: [ValueEntry]) {
        self.instructionQueue = instructionQueue
    }

    // Saves itself to the specified path.
    func save(toFileAtPath path: String) throws {
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
