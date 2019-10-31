//
//  QSInterfaceUrl.swift
//  XMQSeacher
//
//  Created by bin xie on 2019/9/19.
//  Copyright © 2019 小木琴. All rights reserved.
//

import Foundation

private enum Environment {
    case dev
    case test
    case uat
    case produce
}

private let curEnvironment = Environment.test
// MARK: 设置请求接口前缀地址
public let XMQS_baseUrl = settingBaseUrl(curEnvironment)
// MARK: 设置h5前缀地址
public let XMQS_baseWebUrl = settingWebUrl(curEnvironment)

private func settingBaseUrl(_ environment: Environment) -> String {
    
    switch environment
    {
    case .dev:
        return "ddddd"
        
    case .test:
        return "http://server.xmuqin.com:10001/xmuqin-teacher/"
        
    case .uat:
        return "ddddd"
        
    case .produce:
        return "http://server.xmuqin.com:10001/xmuqin-teacher/"
    }
}

private func settingWebUrl(_ environment: Environment) -> String {
    
    switch environment
    {
    case .dev:
        return "ddddd"
        
    case .test:
        return "ddddd"
        
    case .uat:
        return "ddddd"
        
    case .produce:
        return "ddddd"
    }
}

public enum LoginRegister: String {
    case sendSmsCode = "api/sms/sndSmsCode"
    case login = "api/user/login"
}

public enum Home: String {
    case update = "api/sms/sndSmsCode"
}
