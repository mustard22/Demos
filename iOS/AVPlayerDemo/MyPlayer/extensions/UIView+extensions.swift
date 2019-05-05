//
//  UIView+extensions.swift
//  MyPlayer
//
//  Created by mustard on 2017/12/28.
//  Copyright © 2017年 mustard. All rights reserved.
//

import Foundation
import UIKit

/** 扩展：获取|设置UIView的位置、大小
 */
extension UIView {
    /// origin
    var m_origin: CGPoint {
        get {
            return self.frame.origin
        }
        set {
            self.frame.origin = m_origin
        }
    }
    /// width
    var m_width: CGFloat {
        get {
            // getter实现
            return self.frame.size.width
        }
        set {
            // setter实现
            var rect = self.frame
            rect.size.width = m_width
            self.frame = rect
        }
    }
    /// height
    var m_height: CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            var rect = self.frame
            rect.size.height = m_height
            self.frame = rect
        }
    }
    /// left
    var m_left: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            var rect = self.frame
            rect.origin.x = m_left
            self.frame = rect
        }
    }
    /// right
    var m_right: CGFloat {
        get {
            return (self.m_left+self.m_width)
        }
        set {
            var rect = self.frame
            rect.origin.x = m_right - self.m_width
            self.frame = rect
        }
    }
    /// top
    var m_top: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            var rect = self.frame
            rect.origin.y = m_top
            self.frame = rect
        }
    }
    /// bottom
    var m_bottom: CGFloat {
        get {
            return (self.m_top+self.m_height)
        }
        set {
            var rect = self.frame
            rect.origin.y = m_bottom - self.m_height
            self.frame = rect
        }
    }
}
