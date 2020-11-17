//
// Created by sergio on 10/11/2020.
//

import Foundation
import VirtualMachineLib

let f = "/home/sergio/Documents/compis/out.txt"
let programContainer = ProgramContainer.create(fromFileAtPath: f)
guard let programContainer = programContainer else {
    fatalError()
}
let virtualMachine = VirtualMachine(programContainer: programContainer)
virtualMachine.run()