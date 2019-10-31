//
//  RoundProgressBar.swift
//  YMJF
//
//  Created by 谨投 on 2017/11/14.
//  Copyright © 2017年 谨投. All rights reserved.
//

import UIKit

class RoundProgressBar: UIView {

    // 进度槽颜色
    lazy var trackColor = UIColor()
    // 进度条颜色
    lazy var progressColoar = UIColor()
    // 进度槽
    lazy var trackLayer = CAShapeLayer()
    // 进度条
    lazy var progressLayer = CAShapeLayer()
    // 进度条路径（整个圆圈)
    lazy var path = UIBezierPath()
    // 进度条宽度
    lazy var lineWidth = CGFloat()
    // 当前进度
    var progress: Int = 0 {
        didSet{
            if progress > 100
            {
                progress = 100
            }
            else if progress < 0
            {
                progress = 0
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createProgress(startA: Double, endA: Double) -> Void {
        
        // 获取整个进度条圆圈路径
        path.addArc(withCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                    radius: bounds.size.width/2 - lineWidth,
                    startAngle: angleToRadian(startA),
                    endAngle: angleToRadian(endA),
                    clockwise: true)
        
        // 绘制进度槽
        trackLayer.frame = bounds
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        trackLayer.path = path.cgPath
        layer.addSublayer(trackLayer)
        
        // 绘制进度条
        progressLayer.frame = bounds
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColoar.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.path = path.cgPath
        progressLayer.strokeStart = 0
        layer.addSublayer(progressLayer)
    }
    
    // 设置进度（可以设置是否播放动画）
    func setProgress(progressValue: Int) {
        
        progress = progressValue
        progressLayer.strokeEnd = CGFloat(progress)/100.0
        let pathAnima: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnima.duration = 1
        pathAnima.timingFunction = CAMediaTimingFunction(name: .linear)
        pathAnima.fromValue = NSNumber(value: 0.0)
        pathAnima.toValue = NSNumber(value: progress/100)
        pathAnima.fillMode = .forwards
        pathAnima.autoreverses = false
        progressLayer.add(pathAnima, forKey: "strokeEndAnimation")
    }
    
    // 将角度转为弧度
    private func angleToRadian(_ angle: Double)->CGFloat {
        return CGFloat(angle/Double(180.0) * Double.pi)
    }
}
