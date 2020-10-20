//
// Created by sergio on 19/10/2020.
//

import Foundation

// Initial virtual memory pointers for primitive types.
enum MemoryPointer {
    // Global
    static let globalInt = 0
    static let globalFloat = 250
    static let globalChar = 500
    static let globalBool = 750

    // Local
    static let localInt = 1000
    static let localFloat = 1250
    static let localChar = 1500
    static let localBool = 1750

    // Temporary
    static let tempInt = 2000
    static let tempFloat = 2250
    static let tempChar = 2500
    static let tempBool = 2750

    // Literal
    static let litInt = 3000
    static let litFloat = 3250
    static let litChar = 3500
    static let litBool = 3750
}
