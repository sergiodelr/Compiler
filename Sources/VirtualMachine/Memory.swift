//
// Created by sergio on 12/11/2020.
//

import Foundation

class Memory {
    // Returns the type of the value contained in the specified address.
    public class func type<T>(ofAddress address: Int) -> T.Type{
        return type(of: self[address])
    }
    var globalSegment: [Int: Any]
    var literalSegment: [Int: Any]
    var localSegment
}
