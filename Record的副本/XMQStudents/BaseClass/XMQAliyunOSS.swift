//
//  XMQAliyunOSS.swift
//  NewSwift5.0
//
//  Created by 小木琴 on 2019/9/25.
//  Copyright © 2019 RuiXin. All rights reserved.
//

import UIKit

public enum AliyunKey: String {
    case endPoint = "https://oss-cn-shanghai.aliyuncs.com"
    case accessKey = "LTAI4FtpuyjJEFSAZPNXDMDh"
    case secretKey = "5LwXIsHPpIa2lyq42BJyOOSExMSXHU"
    case bucketName = "xmuqin-bucket"
}

class XMQAliyunOSS: NSObject {

    /// 单例
    static let share = XMQAliyunOSS()
    private var client = OSSClient()
    private override init(){
        
    }
    
    private func setupEnvironment() {
        
        OSSLog.enable()
        let provider = OSSPlainTextAKSKPairCredentialProvider.init(plainTextAccessKey: AliyunKey.accessKey.rawValue,
                                                                   secretKey: AliyunKey.secretKey.rawValue)
        client = OSSClient.init(endpoint: AliyunKey.endPoint.rawValue, credentialProvider: provider)
        
    }
    
    public func uploadObjectAsync(_ uploadData: Data,_ objectKey: String) {
        
        setupEnvironment()
        
//        client.uploadData(uploadData, withContentType: "aaa", withObjectMeta:[:], toBucketName: AliyunKey.bucketName.rawValue, toObjectKey: objectKey, onCompleted: { (Bool, Error) in
//
//        }) { (Float) in
//
//        }
        
        /// 上传请求类
        let request = OSSPutObjectRequest()
        /// 文件夹名 后台给出
        request.bucketName = AliyunKey.bucketName.rawValue
        /// objectKey为文件名 一般自己拼接
        request.objectKey = objectKey
        /// 上传数据类型为Data
        request.uploadingData = uploadData
        
        let putTask = client.putObject(request)
        /// 上传进度
        request.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
        debugPrint("bytesSent:\(bytesSent),totalBytesSent:\(totalBytesSent),totalBytesExpectedToSend:\(totalBytesExpectedToSend)");
        };
        
//        UIApplication.shared.keyWindow?.showHud(isCovered: true)
        putTask.continue({ (task) -> Any? in
            
            if task.error == nil
            {
                if task.isCompleted == true {
                    
                    debugPrint("上传成功!")
//                    DispatchQueue.global().async {
//                        DispatchQueue.main.async {
//                            UIApplication.shared.keyWindow?.hideHud()
//                        }
//                    }
                }
            }
            else
            {
                debugPrint("upload object failed, error: ",task.error as Any)
            }
            
            return nil
            }).waitUntilFinished()
        
    }
}
