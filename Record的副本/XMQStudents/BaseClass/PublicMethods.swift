//
//  PublicMethods.swift
//  XMQTeacher
//
//  Created by bin xie on 2019/9/19.
//  Copyright © 2019 小木琴. All rights reserved.
//

import Foundation
import UIKit

public struct ScreenSize {
    let bounds = UIScreen.main.bounds
    let screenW = UIScreen.main.bounds.width
    let screenH = UIScreen.main.bounds.height
    /// 状态栏高度适配
    let statusBarH: CGFloat = DeviceScreen().isiPhoneX ? 44.0 : 20.0
    /// 导航栏高度适配
    let navigationBarH: CGFloat = DeviceScreen().isiPhoneX ? 88.0 : 64.0
    /// 底部TabBar高度适配
    let tabBarH: CGFloat = DeviceScreen().isiPhoneX ? 83.0 : 49.0
    /// 导航栏高度+底部TabBar高度 适配
    let navigationTabBarH: CGFloat = DeviceScreen().isiPhoneX ? 171.0 : 113.0
}

public struct ScreenCGRect {
    let navCGRect = CGRect.init(x: 0,
                                y: 0,
                                width: ScreenSize().screenW,
                                height: ScreenSize().screenH-ScreenSize().navigationBarH)
    let tabCGRect = CGRect.init(x: 0,
                                y: 0,
                                width: ScreenSize().screenW,
                                height: ScreenSize().screenH-ScreenSize().tabBarH)
    let navTabCGRect = CGRect.init(x: 0,
                                   y: 0,
                                   width: ScreenSize().screenW,
                                   height: ScreenSize().screenH-ScreenSize().navigationTabBarH)
}

public struct DeviceScreen {
    var isiPhone5 = UIScreen.main.bounds.width == 320.0 ? true : false
    var isiPhone8 = UIScreen.main.bounds.width == 375.0 ? true : false
    var isiPhone8P = UIScreen.main.bounds.width == 414.0 ? true : false
    var isiPhoneX = UIScreen.main.bounds.height >= 812.0 ? true : false
}

// MARK: 加载动画提示
public func showHUD() {
    
    LoadingHUD.share.showLoading()
}

// MARK: dismiss HUD
public func dismissHUD() {
    
    LoadingHUD.share.dismissLoading()
}

// MARK: 文本提示
public func showTextHUD(_ tips: String) {
    
    LoadingHUD.share.showTextLoading(text: tips)
}

// MARK: 类型转换：String 转为 CGFloat
public func stringToFloat(_ str: String) -> CGFloat {
    
    var cgFloat: CGFloat = 0
    
    if let doubleValue = Double(str)
    {
        cgFloat = CGFloat(doubleValue)
    }
    
    return cgFloat
}

// MARK: 类型转换：String 转为 Int
public func stringToInt(_ str: String) -> Int {
    
    if str.isEmpty
    {
        return 0
    }
    
    var int = Int()
    
    if let intValue = Int(str)
    {
        int = Int(intValue)
    }
    
    return int
}

// MARK: 字典转JSONString
public func getJSONStringFromDictionary(_ dictionary: Dictionary<String, Any>) -> String {
    
    if (!JSONSerialization.isValidJSONObject(dictionary))
    {
        debugPrint("无法解析出JSONString")
        return ""
    }
    
    let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) as Data
    let JSONString = NSString(data:data!,encoding: String.Encoding.utf8.rawValue)
    return JSONString! as String
}

// MARK: JSONString转换为字典
public func getDictionaryFromJSONString(_ jsonString: String) -> Dictionary<String, Any> {
    
    let jsonData = jsonString.data(using: .utf8)!
    let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
    return dict != nil ? dict as! Dictionary<String, Any> : [:]
}

// MARK: 设置控件边框 圆角度
public func setCircleAngle(view: UIView, a: CGFloat) {
    
    view.layer.cornerRadius = a
    view.layer.masksToBounds = true
}

public func setBorderCircleAngle(view: UIView, w: CGFloat, a: CGFloat, c:UIColor) {
    
    view.layer.cornerRadius = a
    view.layer.masksToBounds = true
    view.layer.borderWidth = w
    view.layer.borderColor  = c.cgColor
}

// MARK: 贝塞尔曲线设圆弧
public func setRoundedCorners(_ view: UIView,_ rect: CGRect,
                              _ corners: UIRectCorner,_ radius: CGFloat) {
    
    let maskPath: UIBezierPath = UIBezierPath(roundedRect: rect,
                                              byRoundingCorners: corners,
                                              cornerRadii: CGSize.init(width: radius, height: radius))
    let maskLayer: CAShapeLayer = CAShapeLayer()
    /// 设置大小
    maskLayer.frame = rect
    /// 设置图形样子
    maskLayer.path = maskPath.cgPath
    view.layer.mask = maskLayer
}

// MARK: 设置阴影效果
public func setViewShadow(_ curView: UIView,_ cornerRadius: CGFloat,_ radius: CGFloat) {
    
    curView.layer.cornerRadius = cornerRadius
    curView.backgroundColor = UIColor.white
    let color = UIColor.init(white: 230/255, alpha: 1).cgColor
    curView.layer.shadowColor = color
    curView.layer.shadowOffset = CGSize.init(width: 0, height: 1)
    curView.layer.shadowOpacity = 1
    curView.layer.shadowRadius = radius
}

// MARK: Kingfisher加载图片
public func kingfisherImage(imageView: UIImageView, imageUrl: String) -> Void {
    
    //    let url = URL(string: imageUrl)
    //    imageView.kf.setImage(with: url,
    //                          placeholder: UIImage.init(named: "Bjz_bg"))
}

public func kingfisherBtnImage(btn: UIButton, imageUrl: String) -> Void {
    
    //    let url = URL(string: imageUrl)
    //    btn.kf.setImage(with: url, for: .normal)
}

// MARK: dismiss指定页面
public func dismissSpecified(_ viewController: UIViewController) -> Void {
    
    var specificVC: UIViewController = viewController
    while (specificVC.presentingViewController != nil)
    {
        specificVC = specificVC.presentingViewController!
    }
    
    specificVC.dismiss(animated: true, completion: nil)
}

// MARK: pop指定页面
public func popSpecified(_ navigationController: UINavigationController,_ number: Int) {
    
    let count = (navigationController.viewControllers).count - number
    let publicVC: UIViewController = (navigationController.viewControllers[count])
    navigationController.popToViewController(publicVC, animated: true)
}

