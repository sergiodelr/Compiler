//
// Created by sergio on 10/11/2020.
//

import Foundation
import VirtualMachineLib

if CommandLine.argc == 2 {
    let filePath = CommandLine.arguments[1]
    let programContainer = ProgramContainer.create(fromFileAtPath: filePath)
    guard let pc = programContainer else {
        fatalError("Failed to load program.")
    }
    let virtualMachine = VirtualMachine(programContainer: pc)
    virtualMachine.run()
} else {
    print("Expected one argument: program path.")
}
