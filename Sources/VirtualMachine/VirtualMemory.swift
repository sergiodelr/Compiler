//
// Created by sergio on 12/11/2020.
//

import Foundation
import VirtualMachineLib

protocol Memory {
    subscript(index: Int) -> Any? {get set}
}

public class VirtualMemory: Memory {
    // Private
    var globalSegment: MemorySegment
    var literalSegment: MemorySegment
    var localSegments: Stack<MemorySegment>
    var dynamicSegment: MemorySegment

    // Public
    private(set) public var nextDynamicAddress: Int

    public init(literals: [Int: Any]) {
        globalSegment = MemorySegment()
        literalSegment = MemorySegment(segmentMemory: literals)
        localSegments = Stack<MemorySegment>()
        dynamicSegment = MemorySegment()
        nextDynamicAddress = 0

        // Special case for empty list literal.
        writeDynamicValue(ListCell(value: nil, next: nil))
        literalSegment[MemoryPointer.literalStartAddress + MemoryPointer.listStartAddress] = ListValue(value: 0)
    }

    subscript(index: Int) -> Any? {
        get {
            switch index {
            case MemoryPointer.globalStartAddress ..< MemoryPointer.localStartAddress:
                if let val = globalSegment[index] {
                    return val
                }
            case MemoryPointer.localStartAddress ..< MemoryPointer.literalStartAddress:
                if let localSegment = localSegments.top {
                    if let val = localSegment[index] {
                        return val
                    }
                }
            case MemoryPointer.literalStartAddress ..< (MemoryPointer.literalStartAddress + MemoryPointer.segmentSize):
                if let val = literalSegment[index] {
                    return val
                }
            default:
                break
            }
            // TODO: handle error.
            print("Local mem")
            print(String(reflecting: localSegments.top))
            fatalError("Invalid address get. \(index)")
        }
        set {
            switch index {
            case MemoryPointer.globalStartAddress ..< MemoryPointer.localStartAddress:
                globalSegment[index] = newValue
                return
            case MemoryPointer.localStartAddress ..< MemoryPointer.literalStartAddress:
                if localSegments.top != nil {
                    localSegments.top![index] = newValue
                    return
                }
            case MemoryPointer.literalStartAddress ..< (MemoryPointer.literalStartAddress + MemoryPointer.segmentSize):
                literalSegment[index] = newValue
                return
            default:
                break
            }
            // TODO: handle error.
            fatalError("Invalid address set. \(index)")
        }
    }

    public func pushLocal() {
        localSegments.push(MemorySegment())
    }

    public func popLocal() {
        localSegments.pop()
    }

    public func writeDynamicValue(_ value: Any) {
        dynamicSegment[nextDynamicAddress] = value
        nextDynamicAddress += 1
    }

    public func readDynamicValue(inAddress addr: Int) -> Any {
        if let val = dynamicSegment[addr] {
            return val
        }
        // TODO: Handle error.
        fatalError("Invalid dynamic address. \(addr)")
    }
}

class MemorySegment: Memory, CustomDebugStringConvertible {
    var segmentMemory: [Int: Any]

    public init() {
        segmentMemory = [Int: Any]()
    }

    public init(segmentMemory: [Int: Any]) {
        self.segmentMemory = segmentMemory
    }

    // Memory
    public subscript(index: Int) -> Any? {
        get {
            // User must validate index before calling.
            return segmentMemory[index]
        }
        set {
            segmentMemory[index] = newValue
        }
    }

    // CustomDebugStringConvertible
    var debugDescription: String {
        return String(reflecting: segmentMemory)
    }
}