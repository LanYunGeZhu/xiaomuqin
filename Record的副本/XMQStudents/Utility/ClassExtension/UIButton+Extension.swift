//
//  UIButton+Extension.swift
//  SnapKitDemo
//
//  Created by XieBin on 2019/1/22.
//  Copyright © 2019 XieBin. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    // pragma MARK: 获取验证码按钮 倒计时
    func countdown(_ time: Int,_ normalColor: UIColor,_ changeColor: UIColor,_ borderColor: UIColor) {
        
        var timeOut: Int = time
        let queue = DispatchQueue.global(qos: .default)
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(wallDeadline: DispatchWallTime.now(), repeating: 1)
        timer.setEventHandler {
            /// 倒计时结束，关闭
            if timeOut <= 0
            {
                timer.cancel()
                DispatchQueue.main.async {
                    
                    self.isUserInteractionEnabled = true
                    self.setTitleColor(normalColor, for: .normal)
                    self.setBorder(self, 1, 4, borderColor)
                    self.setTitle("重新获取", for: .normal)
                }
            }
            else
            {
                let allTime: Int = Int(time)+1
                let seconds: Int = timeOut % allTime
                let timeStr: String = "\(CLong(seconds))"
                DispatchQueue.main.async {
                    
                    self.isUserInteractionEnabled = false
                    self.setTitleColor(changeColor, for: .normal)
                    self.setBorder(self, 1, 4, UIColor.white)
                    self.titleLabel?.text = "\(timeStr)S"
                    self.setTitle("\(timeStr)S", for: .normal)
                }
                
                timeOut -= 1
            }
        }
        
        (timer as! DispatchObject).resume()
    }
    
    // pragma MARK: 获取验证码按钮 倒计时
    func codeCountdown(_ timer: DispatchSourceTimer,_ time: Int,_ normalColor: UIColor,_ changeColor: UIColor) {
        
        var timeOut: Int = time
        timer.schedule(wallDeadline: DispatchWallTime.now(), repeating: 1)
        timer.setEventHandler {
            /// 倒计时结束，关闭
            if timeOut <= 0
            {
                timer.cancel()
                DispatchQueue.main.async {
                    
                    self.isUserInteractionEnabled = true
                    self.setTitleColor(normalColor, for: .normal)
                    self.backgroundColor = changeColor
                    self.setTitle("重新获取", for: .normal)
                }
            }
            else
            {
                let allTime: Int = Int(time)+1
                let seconds: Int = timeOut % allTime
                let timeStr: String = "\(CLong(seconds))"
                DispatchQueue.main.async {
                    
                    self.isUserInteractionEnabled = false
                    self.setTitleColor(changeColor, for: .normal)
                    self.backgroundColor = normalColor
                    self.setBorder(self, 1, 4, changeColor)
                    self.titleLabel?.text = "\(timeStr)S"
                    self.setTitle("\(timeStr)S", for: .normal)
                }
                
                timeOut -= 1
            }
        }
        
        (timer as! DispatchObject).resume()
    }
    
    private func setBorder(_ view: UIButton, _ w: CGFloat, _ a: CGFloat, _ c:UIColor) -> Void {
        
        view.layer.cornerRadius = a
        view.layer.masksToBounds = true
        view.layer.borderWidth = w
        view.layer.borderColor  = c.cgColor
    }
}
