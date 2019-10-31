//
//  String+Methods.swift
//  YMJF
//
//  Created by bin xie on 2018/1/11.
//  Copyright © 2018年 小木琴. All rights reserved.
//

import UIKit

extension String {
    
    // pragma MARK: 计算字符串长度
    static func sizeWithText(text: String, fontSize: CGFloat, size: CGSize) -> CGRect {
        
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = text.boundingRect(with: size, options: option, attributes: attributes, context: nil)
        return rect
    }
    
    // pragma MARK: 设置文字行间距
    static func setTextLineLSpacing(str: String, lineSpace: CGFloat) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString.init(string: str)
        let paragraphStye = NSMutableParagraphStyle()
        paragraphStye.lineSpacing = lineSpace
        let rang = NSRange.init(location: 0, length: CFStringGetLength(str as CFString))
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : paragraphStye], range: rang)
        return attributedString
    }
    
    // pragma MARK: 将数字格式化：¥8，900，000
    static func amountFormattedYuanThreeBits(_ amount:String,_ isCurrency: Bool,_ number: Int) -> String {
        
        if amount.count == 0 || Int(amount) == 0
        {
            return "0"
        }
        
        let decimalNumber = NSDecimalNumber(string: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = number
        var newAmount = formatter.string(from: decimalNumber)!
        newAmount = isCurrency ? "¥\(newAmount)" : "\(newAmount)"
        return newAmount
    }
    
    static func amountFormatted(_ amount: String,_ number: Int) -> String {
        
        if amount.count == 0 || Int(amount) == 0 || amount == "0.00"
        {
            return "0.00"
        }
        
        let decimalNumber = NSDecimalNumber(string: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = number
        var newAmount = formatter.string(from: decimalNumber)!
        newAmount = "\(newAmount)"
        return newAmount
    }
    
    static func amountWithoutPoint(_ amount: String) -> String {
        
        if amount.count == 0 || Int(amount) == 0 || amount == "0.00"
        {
            return "0"
        }
        
        let decimalNumber = NSDecimalNumber(string: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 0
        var newAmount = formatter.string(from: decimalNumber)!
        newAmount = "\(newAmount)"
        return newAmount
    }
}

