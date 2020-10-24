//
// Created by sergio on 19/10/2020.
//

import Foundation

// Initial virtual memory pointers for primitive types.
public enum MemoryPointer {
    // Global
    public static let globalInt = 0
    public static let globalFloat = 250
    public static let globalChar = 500
    public static let globalBool = 750

    // Local
    public static let localInt = 1000
    public static let localFloat = 1250
    public static let localChar = 1500
    public static let localBool = 1750

    // Temporary
    public static let tempInt = 2000
    public static let tempFloat = 2250
    public static let tempChar = 2500
    public static let tempBool = 2750

    // Literal
    public static let litInt = 3000
    public static let litFloat = 3250
    public static let litChar = 3500
    public static let litBool = 3750

    public static let addressesPerType = 250
}
