//
//  DataCache.swift
//  YMJF
//
//  Created by bin xie on 2017/12/6.
//  Copyright © 2019年 小木琴. All rights reserved.
//

import UIKit

public enum CacheKey: String {
    case version = "studentsLastVersion"
    case token = "studentsToken"
}

class DataCache: NSObject {
    
    // 单例
    static let share = DataCache()
    private override init(){
    }

    // MARK: 本地缓存变量定义 赋值
    
    /// 最后版本号
    var lastVersion: String = "" {
        didSet{
            setNormalDefault(key: CacheKey.version.rawValue, value: lastVersion as AnyObject)
        }
    }
    /// 用户token
    var token: String = "" {
        didSet{
            setNormalDefault(key: CacheKey.token.rawValue, value: token as AnyObject)
        }
    }
}

extension DataCache {
    
    // MARK: 本地缓存读取
    
    func stringValue(name: String) -> String {
        
        var value = getNormalDefault(key: name)
        
        if value.isKind(of: NSNull.self)
        {
            value = "" as AnyObject
        }
        
        return value as! String
    }
    
    func boolValue(name: String) -> Bool {
        
        var value = getNormalDefault(key: name)
        
        if value.isKind(of: NSNull.self)
        {
            value = false as AnyObject
        }
        
        return value as! Bool
    }
    
    func dictValue(name: String) -> NSDictionary {
        
        var value = getNormalDefault(key: name)
        
        if value.isKind(of: NSNull.self)
        {
            value = [:] as AnyObject
        }
        
        return value as! NSDictionary
    }
    
    // MARK: UserDefaults存储和取值方法封装

    func setNormalDefault(key:String, value:AnyObject?) -> Void {
        
        if value == nil
        {
            UserDefaults.standard.removeObject(forKey: key)
        }
        else
        {
            UserDefaults.standard.set(value, forKey: key)
            // 同步
            UserDefaults.standard.synchronize()
        }
    }
    
    func getNormalDefault(key:String) -> AnyObject {
        
        return UserDefaults.standard.value(forKey: key) as AnyObject
    }
    
    // MARK: 退出清除相关数据
    
    func saveData(_ dict: NSDictionary, _ phone: String) -> Void {
        
        /// 用户token
        token = dict["token"] as! String
    }
    
    func exitClearData() -> Void {
        
        token = ""
    }
}
