//
//  PhotoSelection.swift
//  RCH
//
//  Created by XieBin on 2018/4/13.
//  Copyright © 2018年 XieBin. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class PhotoSelection: NSObject {
    
    fileprivate var currViewController = UIViewController()
    fileprivate var pickerController = UIImagePickerController()
    
    func selectionPhoto(viewController: UIViewController, imageController: UIImagePickerController) {

        currViewController = viewController
        pickerController = imageController
        let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction.init(title: "从手机相册选择", style: .default, handler: { (action) in
            
            self.openImagePickerController(index: 1)
        }))
        alertController.addAction(UIAlertAction.init(title: "拍照", style: .default, handler: { (action) in
            
            self.openImagePickerController(index: 2)
        }))
        alertController.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
            
        }))
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func openImagePickerController(index: Int) {
        
        pickerController.allowsEditing = false
    
        switch index
        {
        case 1:
            let status = PHPhotoLibrary.authorizationStatus()
            
            if status == .restricted || status == .denied
            {
                userAuthorizationAction(imageType: "相册")
                return
            }
            
            pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
            
        default:
            let mediaType: String = AVMediaType.video.rawValue
            let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType(rawValue: mediaType))
            
            if authStatus == .restricted || authStatus == .denied
            {
                userAuthorizationAction(imageType: "相机")
                return
            }
            
            pickerController.sourceType = UIImagePickerController.SourceType.camera
        }
        
        currViewController.present(pickerController, animated: true, completion: nil)
    }
    
    fileprivate func userAuthorizationAction(imageType: String) {
        
        let infoDictionary = Bundle.main.infoDictionary!
        let appName = infoDictionary["CFBundleName"] as! String
        let messageStr = "您未开启APP\(imageType)授权，请到“设置-\(appName)-\(imageType)中启用访问"
        let alertVc = UIAlertController.init(title: "温馨提示", message: messageStr, preferredStyle: .alert)
        let action1 = UIAlertAction.init(title: "取消", style: .cancel) { (action) in
            
        }
        let action2 = UIAlertAction.init(title: "去设置", style: .default) { (action) in
            
            UIApplication.shared.openURL(URL.init(string: UIApplication.openSettingsURLString)!)
        }
        alertVc.addAction(action1)
        alertVc.addAction(action2)
        currViewController.present(alertVc, animated: true, completion: nil)
    }
}
