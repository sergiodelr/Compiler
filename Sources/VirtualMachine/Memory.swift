//
// Created by sergio on 12/11/2020.
//

import Foundation
import VirtualMachineLib

class Memory {
    // Private
    var globalSegment: [Int: Any]
    var literalSegment: [Int: Any]
    var localSegment: Stack<[Int: Any]>

    // Public
    init(literals: [Int: Any]) {
        globalSegment = [Int: Any]()
        literalSegment = literals
        localSegment = Stack<[Int: Any]>()
    }

    subscript(index: Int) -> Any {
        get {
            switch index {
            case MemoryPointer.globalStartAddress ..< MemoryPointer.localStartAddress:
                if let val = globalSegment[index] {
                    return val
                }
            case MemoryPointer.localStartAddress ..< MemoryPointer.literalStartAddress:
                if let localSegment = localSegment.top {
                    if let val = globalSegment[index] {
                        return val
                    }
                }
            case MemoryPointer.literalStartAddress ..< MemoryPointer.literalStartAddress + MemoryPointer.segmentSize:
                if let val = globalSegment[index] {
                    return val
                }
            default:
                break
            }
            // TODO: handle error.
            fatalError("Invalid address.")
        }
        set {
            switch index {
            case MemoryPointer.globalStartAddress ..< MemoryPointer.localStartAddress:
                globalSegment[index] = newValue
            case MemoryPointer.localStartAddress ..< MemoryPointer.literalStartAddress:
                if var localSegment = localSegment.top {
                    localSegment[index] = newValue
                }
            case MemoryPointer.literalStartAddress ..< MemoryPointer.literalStartAddress + MemoryPointer.segmentSize:
                literalSegment[index] = newValue
            default:
                break
            }
            // TODO: handle error.
            fatalError("Invalid address.")
        }
    }
}
