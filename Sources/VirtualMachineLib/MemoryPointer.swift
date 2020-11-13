//
// Created by sergio on 19/10/2020.
//

import Foundation

// Initial virtual memory pointers for primitive types.
public enum MemoryPointer {
    // Global
    public static let globalStartAddress = 0

    // Local
    public static let localStartAddress = 3000

    // Temporary
    public static let tempStartAddress = 6000

    // Literal
    public static let literalStartAddress = 9000

    // Addresses per type.
    public static let addressesPerType = 500

    // Segment size.
    public static let segmentSize = 3000

    // Start addresses for each type. Actual start address is segmentStartAddress (global, etc) + typeStartAddress.
    public static let intStartAddress = 0
    public static let floatStartAddress = 500
    public static let charStartAddress = 1000
    public static let boolStartAddress = 1500
    public static let funcStartAddress = 2000
    public static let listStartAddress = 2500
}
