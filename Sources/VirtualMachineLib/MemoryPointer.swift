//
// Created by sergio on 19/10/2020.
//

import Foundation

// Initial virtual memory pointers for primitive types.
public enum MemoryPointer {
    // Global
    public static let globalStartAddress = 0

    // Local
    public static let localStartAddress = 1000

    // Temporary
    public static let tempStartAddress = 2000

    // Literal
    public static let literalStartAddress = 3000

    public static let addressesPerType = 200
}
