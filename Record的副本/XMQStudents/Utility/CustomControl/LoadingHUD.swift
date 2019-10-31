//
//  LoadingHUD.swift
//  ZRTStore
//
//  Created by bin xie on 2018/2/5.
//  Copyright © 2018年 小木琴. All rights reserved.
//

import UIKit

private let ballScale: CGFloat = 1.2
private let ballWidth: CGFloat = 8.0
private let margin: CGFloat = 6.0
private let durationdValue: TimeInterval = 0.8
private let dotColor = UIColor.init(red: 52/255, green: 132/255, blue: 253/255, alpha: 1)
private let size = CGSize.init(width: 50, height: 50)

class LoadingHUD: UIView {
    
    /// 单例
    static let share = LoadingHUD()
    lazy var spotLayer = CALayer()
    lazy var isLoading = Bool()
    
    lazy var indicatorView: UIView = {
        let tempView = UIView.init(frame: CGRect.init(x: 20, y: 11, width: 50, height: 50))
        return tempView
    }()
    
    lazy var masksView: UIView = {
        let tempView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 90, height: 90))
        tempView.center = CGPoint.init(x: bounds.midX, y: bounds.midY)
        tempView.backgroundColor = UIColor.white
        tempView.layer.cornerRadius = 8
        tempView.layer.shadowColor = UIColor.init(white: 0, alpha: 0.5).cgColor
        tempView.layer.shadowOffset = CGSize.init(width: 1, height: 1)
        tempView.layer.shadowOpacity = 1
        tempView.layer.shadowRadius = 8
        return tempView
    }()
    
    lazy var tipsLb: UILabel = {
        let tempLb = UILabel.init(frame: CGRect.init(x: 0, y: 67, width: 90, height: 15))
        tempLb.textColor = UIColor.white
        tempLb.font = UIFont.systemFont(ofSize: 13)
        tempLb.text = "加载中..."
        tempLb.textColor = UIColor.init(white: 102/255, alpha: 1)
        tempLb.textAlignment = .center
        return tempLb
    }()
    
    lazy var tipsMaskView: UIView = {
        let tempView = UIView()
        tempView.layer.cornerRadius = 3
        tempView.layer.masksToBounds = true
        tempView.backgroundColor = UIColor.init(white: 0.8, alpha: 0.8)
        return tempView
    }()
    
    lazy var textTipsLoading: UILabel = {
        let tempLb = UILabel()
        tempLb.textColor = UIColor.black
        tempLb.numberOfLines = 0
        tempLb.font = UIFont.systemFont(ofSize: 14)
        tempLb.backgroundColor = UIColor.clear
        return tempLb
    }()

    override init(frame: CGRect) {
        super.init(frame: CGRect.init(x: 0,
                                      y: 0,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// pragma MARK: ------------------ getter/setter -------------------

extension LoadingHUD {
    
    private func configAnimation(_ tempLayer: CALayer) {
        
        let replicatorLayer = CAReplicatorLayer()
        replicatorLayer.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
        replicatorLayer.position = CGPoint.init(x: size.width/2, y: size.width/2)
        replicatorLayer.backgroundColor = UIColor.clear.cgColor
        tempLayer.addSublayer(replicatorLayer)
        addCyclingSpotAnimation(replicatorLayer)
        
        let numOfDot = 10
        replicatorLayer.instanceCount = numOfDot
        replicatorLayer.instanceTransform = CATransform3DMakeRotation(CGFloat((.pi * 2)/Double(numOfDot)), 0, 0, 1)
        replicatorLayer.instanceDelay = 1.5/Double(numOfDot)
    }
    
    private func addCyclingSpotAnimation(_ curLayer: CALayer) {
        
        spotLayer.bounds = CGRect.init(x: 0, y: 0, width: size.width/6, height: size.width/6)
        spotLayer.position = CGPoint.init(x: size.width/2, y: 5)
        spotLayer.cornerRadius = spotLayer.bounds.width/2
        spotLayer.backgroundColor = dotColor.cgColor
        spotLayer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
        curLayer.addSublayer(spotLayer)
        
        let animation = CABasicAnimation.init(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 0.1
        animation.duration = 1.5
        animation.repeatCount = Float(CGFloat.greatestFiniteMagnitude)
        spotLayer.add(animation, forKey: "animation")
    }
    
    private func removeAnimation() {
        
        spotLayer.removeAnimation(forKey: "animation")
    }
}

// pragma MARK: ------------------ private Method ------------------

extension LoadingHUD {
    
    private func sizeWithText(text: String, fontSize: CGFloat) -> CGRect {
        
        let size = CGSize.init(width: UIScreen.main.bounds.width - 100.0, height: UIScreen.main.bounds.height - 300.0)
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = text.boundingRect(with: size, options: option, attributes: attributes, context: nil)
        return rect
    }
    
    private func getAttributeString(str: String,lineSpace: CGFloat) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString.init(string: str)
        let paragraphStye = NSMutableParagraphStyle()
        paragraphStye.lineSpacing = lineSpace
        let rang = NSRange.init(location: 0, length: CFStringGetLength(str as CFString))
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : paragraphStye], range: rang)
        return attributedString
    }
    
    // MARK: 放大过程中出现的缓慢动画
    
    private func shakeToShow(view: UIView) -> Void {
        
        let shakeAnimation = CAKeyframeAnimation.init(keyPath: "transform")
        shakeAnimation.duration = 0.3
        var values = [NSValue]()
        values.append(NSValue.init(caTransform3D: CATransform3DMakeScale(0.1, 0.1, 1.0)))
        values.append(NSValue.init(caTransform3D: CATransform3DMakeScale(1.0, 1.0, 1.0)))
        shakeAnimation.values = values
        view.layer.add(shakeAnimation, forKey: "shakeAnimation")
    }
}

// pragma MARK: -------------------- Show dismiss ------------------

extension LoadingHUD {
    
    func showLoading() -> Void {
        
        DispatchQueue.main.async {
            
            UIApplication.shared.keyWindow?.addSubview(self)
            self.addSubview(self.masksView)
            self.masksView.addSubview(self.indicatorView)
            self.masksView.addSubview(self.tipsLb)
            self.configAnimation(self.indicatorView.layer)
            self.isLoading = true
        }
    }
    
    func dismissLoading() -> Void {
        
        if isLoading
        {
            DispatchQueue.main.async {
                
                self.removeAnimation()
                self.indicatorView.removeFromSuperview()
                self.tipsLb.removeFromSuperview()
                self.masksView.removeFromSuperview()
                self.removeFromSuperview()
                self.isLoading = false
            }
        }
    }
    
    func showTextLoading(text: String) -> Void {
        
        if text.isEmpty
        {
            return
        }
        
        DispatchQueue.main.async {
            
            self.textTipsLoading.attributedText = self.getAttributeString(str: text, lineSpace: 3.0)
            let textStr: String = (self.textTipsLoading.attributedText?.string)!
            let textSize: CGRect = self.sizeWithText(text: textStr, fontSize: 14)
            let lbW: CGFloat = textSize.width + 20.0
            let lbH: CGFloat = textSize.height + 16.0
            self.tipsMaskView.frame = CGRect.init(x: 0, y: 0, width: lbW, height: lbH)
            self.tipsMaskView.center = CGPoint.init(x: UIScreen.main.bounds.width/2.0, y: UIScreen.main.bounds.height/2.0)
            self.textTipsLoading.frame = CGRect.init(x: 0, y: 0, width: lbW - 20, height: lbH - 10.0)
            self.textTipsLoading.center = CGPoint.init(x: self.tipsMaskView.bounds.midX, y: self.tipsMaskView.bounds.midY)
            UIApplication.shared.keyWindow?.addSubview(self.tipsMaskView)
            self.textTipsLoading.textAlignment = .center
            self.tipsMaskView.addSubview(self.textTipsLoading)
            self.shakeToShow(view: self.tipsMaskView)
        }
    
        DispatchQueue.main.asyncAfter(deadline: .now()+2.0, execute: {
            
            self.textTipsLoading.removeFromSuperview()
            self.tipsMaskView.removeFromSuperview()
        })
    }
}
