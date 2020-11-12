//
// Created by sergio on 12/11/2020.
//

import Foundation
import VirtualMachineLib

public class VirtualMachine {
    let instructionQueue: InstructionQueue
    var instructionPointer = 0

    var memory: Memory

    public init(programContainer: ProgramContainer) {
        instructionQueue = programContainer.instructionQueue
    }

    public func run() {

    }

    func runQuads() {
        let quad = instructionQueue[instructionPointer]
        // Optionals are force unwrapped because they are guaranteed to contain a value unless program file is corrupt.
        // TODO: Validate that quadruples contain expected values.
        while true {
            switch quad.instruction {
            case .add:
                numericOperation(+, quad.first!, quad.second!, quad.res!)
            case .subtract:
                <#code#>
            case .divide:
                <#code#>
            case .multiply:
                <#code#>
            case .and:
                <#code#>
            case .or:
                <#code#>
            case .not:
                <#code#>
            case .positive:
                <#code#>
            case .negative:
                <#code#>
            case .equal:
                <#code#>
            case .notEqual:
                <#code#>
            case .lessThan:
                <#code#>
            case .greaterThan:
                <#code#>
            case .lessEqual:
                <#code#>
            case .greaterEqual:
                <#code#>
            case .cons:
                <#code#>
            case .append:
                <#code#>
            case .assign:
                <#code#>
            case .car:
                <#code#>
            case .cdr:
                <#code#>
            case .goToFalse:
                <#code#>
            case .goToTrue:
                <#code#>
            case .goTo:
                <#code#>
            case .ret:
                <#code#>
            case .read:
                <#code#>
            case .print:
                <#code#>
            case .importCon:
                <#code#>
            case .alloc:

                <#code#>
            case .arg:
                <#code#>
            case .call:
                <#code#>
            case .receiveRes:
                <#code#>
            case .placeholder:
                <#code#>
            @unknown default:
                <#code#>
            }
        }
    }

    // Performs
    func numericOperation(_ op: (Numeric, Numeric) -> Numeric, _ lAddr: Int,  _ rAddr: Int, _ resAddr: Int) {
        let left = memory[lAddr]
        let right = memory[rAddr]
        let res = memory[resAddr]
    }
}
