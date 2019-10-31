//
//  UIColor+Methods.swift
//  YMJF
//
//  Created by bin xie on 2018/1/11.
//  Copyright © 2018年 小木琴. All rights reserved.
//

import UIKit

extension UIColor {
    
    // MARK: 颜色
    static func setRGBColor(r: CGFloat,g: CGFloat,b: CGFloat) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1)
    }
    
    static func setRGBAColor(r: CGFloat,g: CGFloat,b: CGFloat,a: CGFloat) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
    // 十六进制颜色转换
    static func colorHexString(_ colorStr: String) -> UIColor {
        
        var color = UIColor.red
        var cStr : String = colorStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if cStr.hasPrefix("#")
        {
            let index = cStr.index(after: cStr.startIndex)
            let newStr = String(cStr[index...])
            cStr = newStr
        }
        
        if cStr.count != 6
        {
            return UIColor.black
        }
        
        let rRange = cStr.startIndex ..< cStr.index(cStr.startIndex, offsetBy: 2)
        let rStr = String(cStr[rRange])
        
        let gRange = cStr.index(cStr.startIndex, offsetBy: 2) ..< cStr.index(cStr.startIndex, offsetBy: 4)
        let gStr = String(cStr[gRange])
        
        let bIndex = cStr.index(cStr.endIndex, offsetBy: -2)
        let bStr = String(cStr[bIndex...])
        
        var r: CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0
        Scanner(string: rStr).scanHexInt32(&r)
        Scanner(string: gStr).scanHexInt32(&g)
        Scanner(string: bStr).scanHexInt32(&b)
        color = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
        return color
    }
}

