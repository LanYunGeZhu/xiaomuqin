//
//  UIview+Extension.swift
//  XMQStudents
//
//  Created by 宋丰 on 2019/10/22.
//  Copyright © 2019 小木琴. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    func showHud(isCovered: Bool = false) {
        
        let www:CGRect =  String.sizeWithText(text: " 正在上传，请稍后... ", fontSize: 12, size: CGSize.init(width: UIScreen.main.bounds.size.width, height: 20))
        let frame = CGRect(x: 0, y: 0, width: www.size.width, height: 80)
        
        let backVFrame = isCovered == false ? frame : self.frame
        let backV = UIView(frame: backVFrame)
        backV.center = self.center
        backV.tag = 8421
        self.addSubview(backV)
        
        let hudV = UIView(frame: frame)
        hudV.center = CGPoint(x: backV.frame.width/2, y: backV.frame.height/2)
        hudV.layer.cornerRadius = 12
        hudV.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.8)
        backV.addSubview(hudV)
        
        let indicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        indicatorView.frame = CGRect(x: (www.size.width-36)/2, y: 15, width: 36, height: 36)
        indicatorView.startAnimating()
        hudV.addSubview(indicatorView)
        
        //UILabel
        let label = UILabel(frame:CGRect(x:0, y:55, width:hudV.frame.width,height:20))
        label.text = "正在上传，请稍后..."
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = UIColor.white
        hudV.addSubview(label)
        
        hudV.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            hudV.alpha = 1
        })
    }
    
    func hideHud() {
        
        let backV = self.viewWithTag(8421)
        guard let backv = backV else { return }
        backv.removeFromSuperview()
    }
    
}
