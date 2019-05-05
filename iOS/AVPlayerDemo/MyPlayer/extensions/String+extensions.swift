//
//  String+extensions.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/28.
//  Copyright © 2017年 mustard. All rights reserved.
//

import Foundation

extension String {
    /// 扩展：字符串MD5加密
    var MD5: String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deinitialize()
        return String(format: hash as String)
    }
    
    
}
