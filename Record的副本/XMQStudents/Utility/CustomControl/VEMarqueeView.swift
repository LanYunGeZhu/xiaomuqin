//
//  VEMarqueeView.swift
//  RXShopping
//
//  Created by RuiXin on 2019/4/16.
//  Copyright © 2019   小木琴. All rights reserved.
//

import UIKit

class VEMarqueeView: UIView {

    private var mark1 = CGRect()
    private var mark2 = CGRect()
    private var labArr = [UILabel]()
    private var isStop = false
    private var timeInterval1 = TimeInterval()
    lazy var textColor = UIColor()
    lazy var reserveTextLb = UILabel()
    lazy var isFirst = Bool()
    
    lazy var marqueeLb: UILabel = {
        let tempLb = UILabel()
        tempLb.frame = CGRect.zero
        tempLb.textColor = textColor
        tempLb.font = UIFont.systemFont(ofSize: 14)
        tempLb.text = marqueeTitle
        return tempLb
    }()
    
    var marqueeTitle = String() {
        didSet{
            timeInterval1 = TimeInterval.init(marqueeTitle.count/5)
            marqueeLb.text = marqueeTitle
            //计算textLab的大小
            let sizeOfText = marqueeLb.sizeThatFits(CGSize.zero)
            mark1 = CGRect(x: 0, y: 0, width: sizeOfText.width+30, height: bounds.height)
            marqueeLb.frame = mark1
            
            let useReserve = sizeOfText.width > frame.size.width ? true : false
            
            if !labArr.contains(marqueeLb)
            {
                addSubview(marqueeLb)
                labArr.append(marqueeLb)
            }
            
            if useReserve == true
            {
                mark2 = CGRect(x: mark1.origin.x + mark1.width,
                               y: 0,
                               width: sizeOfText.width,
                               height: bounds.height)
                reserveTextLb.frame = mark2
                reserveTextLb.text = marqueeTitle
                
                if !isFirst
                {
                    isFirst = true
                    reserveTextLb.textColor = textColor
                    reserveTextLb.font = UIFont.systemFont(ofSize: 14)
                    addSubview(reserveTextLb)
                    labArr.append(reserveTextLb)
                    labAnimation()
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow != nil
        {
            start()
        }
        else
        {
            stop()
        }
    }
    
    /// 跑马灯动画
    private func labAnimation() {
        
        if !isStop
        {
            let lbindex0 = labArr[0]
            let lbindex1 = labArr[1]
            UIView.transition(with: self, duration: timeInterval1, options: .curveLinear, animations: {
                
                lbindex0.frame = CGRect(x: -self.mark1.width,
                                        y: 0,
                                        width: self.mark1.width,
                                        height: self.mark1.height)
                lbindex1.frame = CGRect(x: lbindex0.frame.origin.x + lbindex0.frame.size.width,
                                        y: 0,
                                        width: lbindex1.frame.width,
                                        height: lbindex1.frame.height)
            }) { (finished) in
                
                lbindex0.frame = self.mark2
                lbindex1.frame = self.mark1
                self.labArr[0] = lbindex1
                self.labArr[1] = lbindex0
                self.labAnimation()
            }
        }
        else
        {
            layer.removeAllAnimations()
        }
    }
    
    private func start() {
        
        if marqueeTitle.isEmpty || labArr.count < 2
        {
            return
        }
        
        isStop = false
        let lbindex0 = labArr[0]
        let lbindex1 = labArr[1]
        lbindex0.frame = mark2
        lbindex1.frame = mark1
        labArr[0] = lbindex1
        labArr[1] = lbindex0
        labAnimation()
    }
    
    private func stop() {
        
        if marqueeTitle.isEmpty || labArr.count < 2
        {
            return
        }
        
        isStop = true
        let lbindex0 = labArr[0]
        let lbindex1 = labArr[1]
        lbindex0.frame = mark2
        lbindex1.frame = mark1
        labArr[0] = lbindex1
        labArr[1] = lbindex0
        labAnimation()
    }
}
