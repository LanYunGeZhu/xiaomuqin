//
//  VENetworkRequest.swift
//
//  Created by XieBin on 2019/1/15.
//  Copyright © 2019 XieBin. All rights reserved.
//

import UIKit
import Alamofire
import Reachability

class VENetworkRequest: NSObject {
    
    /// 单例
    static let share = VENetworkRequest()
    private var manager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        /// 设置请求超时
        configuration.timeoutIntervalForRequest = 5
        /// 设置最大连接数
        configuration.httpMaximumConnectionsPerHost = 5
        return SessionManager.init(configuration: configuration)
    }()
}

// pragma MARK: ------------- 接口URL 入参设置 -------------

extension VENetworkRequest {
    
    // MARK: 拼接完整的url
    private func getCompleteUrl(_ url: String) -> String {
        
        verificationCertificate()
        let newUrl = XMQS_baseUrl.appending(url)
        return newUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
    
    // MARK: https证书验证
    private func verificationCertificate() -> Void {
        
        manager.delegate.sessionDidReceiveChallenge = { session,challenge in
            
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
            {
                disposition = URLSession.AuthChallengeDisposition.useCredential
                credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
            }
            else
            {
                if challenge.previousFailureCount > 0
                {
                    disposition = .cancelAuthenticationChallenge
                }
                else
                {
                    credential = self.manager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                    
                    if credential != nil
                    {
                        disposition = .useCredential
                    }
                }
            }
            
            return (disposition, credential)
        }
    }
}

// pragma MARK: ------------- 网络请求方法封装 -------------

extension VENetworkRequest {
    
    /// 无入参get请求
    ///
    /// - Paraments:
    ///  - url: 拼接接口地址
    ///  - showLoad: 是否显示HUD
    ///  - success: 成功闭包回调
    ///  - failure: 失败闭包回调
    open func getRequest(_ url: String,
                         _ showLoad: Bool,
                         _ success: @escaping(AnyObject,NSNumber)->(),
                         _ failure: @escaping(Error)->()) {
        
        if showLoad
        {
            showHUD()
        }
        
        manager.request(url).responseJSON { (response) in
            
            debugPrint("接口名:",url)
            switch(response.result)
            {
            case .success(let value):
                let dic = value as! NSDictionary
                let status = dic.object(forKey: "code") as! NSNumber
                debugPrint("返回数据:",dic)
                
                if status == 200
                {
                    var resultData: Any = [:]
                    
                    if dic.object(forKey: "result") != nil
                    {
                        resultData = dic.object(forKey: "result") as Any
                    }
                    
                    success((resultData as AnyObject),status)
                }
                else
                {
                    let message = dic.object(forKey: "message") as! String
                    success((message as AnyObject),status)
                }
                
                break
                
            case .failure(let error):
                debugPrint("返回错误信息:",error)
                failure(error)
                
                break
            }
            
            if showLoad
            {
                dismissHUD()
            }
        }
    }
    
    /// get，post请求
    ///
    /// - Paraments:
    ///  - url: 拼接接口地址
    ///  - method: get,post请求方法
    ///  - showLoad: 是否显示HUD
    ///  - params: 请求入参
    ///  - success: 成功闭包回调
    ///  - failure: 失败闭包回调
    open func requestParams(_ url: String,
                            _ method: HTTPMethod,
                            _ showLoad: Bool,
                            _ params: Dictionary<String, Any>,
                            _ success: @escaping(AnyObject,String)->(),
                            _ failure: @escaping(Error)->()) {
        
        if showLoad
        {
            showHUD()
        }
        
        let token = DataCache.share.stringValue(name: CacheKey.token.rawValue)
        let header = ["Content-Type": "application/json",
                      "TOKEN": token,
                      "VERSION": "1.0",
                      "REQ_TYPE": "IOS"]
        let getUrl = getCompleteUrl(url)
        debugPrint("接口名:",getUrl)
        debugPrint("入参:",params)
        
        manager.request(getUrl,
                        method: method,
                        parameters: params,
                        encoding: JSONEncoding.default,
                        headers: header).responseJSON { (response) in
                            
                            switch(response.result)
                            {
                            case .success(let value):
                                let dic = value as! NSDictionary
                                let status = dic.object(forKey: "code") as! String
                                debugPrint("返回数据:",dic)
                                
                                if status == "0000"
                                {
                                    var resultData: Any = [:]
                                    
                                    if (dic.object(forKey: "data") != nil)
                                    {
                                        resultData = dic.object(forKey: "data") as Any
                                    }
                                    else
                                    {
                                        resultData = dic
                                    }
                                    
                                    success((resultData as AnyObject),status)
                                }
                                else
                                {
                                    let message = dic.object(forKey: "msg") as! String
                                    success((["msg" : message] as AnyObject),status)
                                    showTextHUD(message)
                                }
                                
                                break
                                
                            case .failure(let error):
                                
                                showTextHUD("加载失败，请检查网络设置后再试")
                                debugPrint("返回错误信息:",error)
                                failure(error)
                                break
                            }
                            
                            if showLoad
                            {
                                dismissHUD()
                            }
        }
    }
    
    /// 上传图片的数据
    /// 注意，图片必须为Data||NSData类型，其他参数尽量传String或者NSString
    ///
    /// - Paraments:
    ///  - url: 拼接接口地址
    ///  - showLoad: 是否显示HUD
    ///  - params: 请求入参
    ///  - progress: 上传进度
    ///  - success: 成功闭包回调
    ///  - failure: 失败闭包回调
    open func uploadImage(_ url: String,
                          _ showLoad: Bool,
                          _ params: Dictionary<String, Any>,
                          _ progress: @escaping(AnyObject)->(),
                          _ success: @escaping(AnyObject)->(),
                          _ failure: @escaping(Error)->()) {
        
        if showLoad
        {
            showHUD()
        }
        
        let getUrl = getCompleteUrl(url)
        debugPrint("接口名:",getUrl)
        debugPrint("入参:",params)
        manager.upload(multipartFormData: { (multipartFormData) in
            
            for (key, value) in params
            {
                if value is UIImage
                {
                    let formatter: DateFormatter = DateFormatter()
                    // 设置时间格式
                    formatter.dateFormat = "yyyyMMddHHmmss"
                    let dateString = formatter.string(from: NSDate() as Date)
                    let name = "\(dateString)"
                    let imageName = String(describing: "RXImage"+name).appending(".jpg")
                    let image = value as! UIImage
                    let imageData = image.jpegData(compressionQuality: 0.5)
                    multipartFormData.append(imageData!, withName: "img", fileName: imageName, mimeType: "image/jpeg")
                }
                else if value is NSArray
                {
                    let images: NSArray = value as! NSArray
                    
                    for i in 0..<images.count
                    {
                        let formatter: DateFormatter = DateFormatter()
                        // 设置时间格式
                        formatter.dateFormat = "yyyyMMddHHmmss"
                        let dateString = formatter.string(from: NSDate() as Date)
                        let name = "\(dateString)\(CLong(i))"
                        let imageName = String(describing: "RXImage"+name).appending(".jpg")
                        let image = images[i] as! UIImage
                        let imageData = image.jpegData(compressionQuality: 0.5)
                        multipartFormData.append(imageData!, withName: "img", fileName: imageName, mimeType: "image/jpeg")
                    }
                }
                else
                {
                    // 上传图片带参 表单形式提交
                    let str = "\(value)"
                    multipartFormData.append(str.data(using: .utf8)!, withName: key)
                }
            }
            
        }, to: getUrl) { (encodingResult) in
            
            switch encodingResult
            {
            case .success(let upload, _, _):
                upload.uploadProgress { (progressValue) in
                    
                    debugPrint("图片上传进度:",progressValue)
                    progress(progressValue as AnyObject)
                }
                
                upload.responseJSON(completionHandler: { (response) in
                    
                    debugPrint("返回数据:",response.result)
                    switch(response.result)
                    {
                    case .success(let value):
                        success(value as AnyObject)
                        break
                        
                    case .failure(let error):
                        failure(error)
                        break
                    }
                })
                break
                
            case .failure(let error):
                failure(error)
                break
            }
            
            if showLoad
            {
                dismissHUD()
            }
        }
    }
}

extension VENetworkRequest {
    
    open func currentNetReachability(_ netStatus: @escaping(String)->()) {
        
        let netManager = NetworkReachabilityManager()
        netManager?.listener = { status in
            
            var statusStr = String()
            switch status
            {
            case .unknown:
                statusStr = "未识别的网络"
                
            case .notReachable:
                statusStr = "未连接网络"
                
            case .reachable(.wwan):
                statusStr = "2G,3G,4G网络"
                
            case .reachable(.ethernetOrWiFi):
                statusStr = "WiFi网络"
            }
            netStatus(statusStr)
        }
        netManager?.startListening()
    }
    
    open func networkStatus(_ net: @escaping(String)->()) {
        
        let reachability = Reachability()
        var statusStr = String()
        switch reachability!.connection
        {
        case .none:
            statusStr = "网络不可用"
            
        case .cellular:
            statusStr = "2G,3G,4G网络"
            
        case .wifi:
            statusStr = "WiFi网络"
        }
        net(statusStr)
    }
}


