//
//  AnimationMethods.swift
//  ZRTStore
//
//  Created by bin xie on 2018/2/11.
//  Copyright © 2018年 小木琴. All rights reserved.
//

import UIKit

func bottomPopupAnimation(view: UIView) -> Void {
    
    view.transform = CGAffineTransform.init(translationX: 0, y: view.bounds.height)
    UIView.animate(withDuration: 0.4) {
        view.transform = CGAffineTransform.identity
    }
}

func downExitAnimation(view: UIView) -> Void {
    
    UIView.animate(withDuration: 0.5, animations: {
        
        view.bounds.origin.y = -UIScreen.main.bounds.height
    }) { (finished) in
        
        view.bounds.origin.y = 0
        view.removeFromSuperview()
    }
}

func shakeAnimation(view: UIView) -> Void {
    
    let shake = CABasicAnimation.init(keyPath: "transform.translation.x")
    shake.duration = 0.3
    shake.fromValue = NSNumber.init(value: -5.0)
    shake.toValue = NSNumber.init(value: 5.0)
    shake.autoreverses = true
    view.layer.add(shake, forKey: "DongQiLai")
}

func scaleAnimation(_ view: UIView,_ from: Float,_ to: Float) -> Void {
    
    let scaleAnim = CABasicAnimation.init(keyPath: "transform.scale")
    scaleAnim.fromValue = from
    scaleAnim.toValue = to
    scaleAnim.duration = 0.4
    scaleAnim.repeatCount = 1
    view.layer.add(scaleAnim, forKey: "scaleAnim")
}

func opacityAnimation(view: UIView) -> Void {
    
    let alphaAnim = CABasicAnimation.init(keyPath: "opacity")
    alphaAnim.fromValue = 1
    alphaAnim.toValue = 0
    alphaAnim.duration = 0.3
    alphaAnim.autoreverses = true
    alphaAnim.repeatCount = 1
    view.layer.add(alphaAnim, forKey: "alphaAnim")
    view.removeFromSuperview()
}
