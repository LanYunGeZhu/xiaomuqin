//
//  RSWKWebView.swift
//  ZRTStore
//
//  Created by RuiXin on 2019/4/4.
//  Copyright © 2019 谨投. All rights reserved.
//

import UIKit
import WebKit

func getArrayFromJSONString(jsonString: String) -> NSArray {
    
    let jsonData:Data = jsonString.data(using: .utf8)!
    let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
    return array as! NSArray
}

class RSWKWebView: UIView {
    lazy var webView: WKWebView = {
        ///偏好设置
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaPlaybackRequiresUserAction = false
        configuration.preferences = preferences
        configuration.selectionGranularity = WKSelectionGranularity.character
        configuration.userContentController = WKUserContentController()
        // 给webview与swift交互起名字，webview给swift发消息的时候会用到
        configuration.userContentController.add(self, name: "submitMeasureRange")
        let tempView = WKWebView.init(frame: bounds, configuration: configuration)
        tempView.navigationDelegate = self
        tempView.uiDelegate = self
        tempView.scrollView.showsVerticalScrollIndicator = false
        tempView.scrollView.showsHorizontalScrollIndicator = false
        return tempView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(webView)
        self.reloadWeb(number: "车尔尼599-019")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadWeb(number: String) {
        //服务器
//        let webUrl = "https://www.xmuqin.com/staff-view/follow.html?https://www.xmuqin.com/musicXML/"+number+".xml&pw=15"
        //本地
        let webUrl = "http://10.112.25.40:8000/follow.html?http://10.112.25.40:8000/车尔尼599-019.xml&pw=15"
        let newUrl = webUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! // iOS 9之后。
        webView.load(URLRequest.init(url: URL.init(string: newUrl)!,
                                     cachePolicy: .reloadIgnoringLocalCacheData,
                                     timeoutInterval: 5))
//        let fileURL =  Bundle.main.url(forResource: "follow", withExtension: "html")
//        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
    }
}

// pragma MARK: ------------- Delegate ---------------

extension RSWKWebView: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        debugPrint(message.body,"=======================")

        if message.body is NSArray
        {
            switch message.name {
            case "submitMeasureRange":
                //单个参数
                print("\(message.body)")
                UserDefaults.standard.set(message.body, forKey: "fragment")
                UserDefaults.standard.synchronize()
            default: break
            }
        }
        
    }
}

extension RSWKWebView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        showHUD()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    
        dismissHUD()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        showTextHUD("加载失败，请稍后再试")
    }
}

extension RSWKWebView: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
//        switch prompt
//        {
//        case "getToken":
//            let token = DataCache.share.stringValue(name: TOKEN)
//            completionHandler(token)
//            
//        case "getUserInfo":
//            let userInfo = DataCache.share.dictValue(name: USERINFO)
//            let jsString = getJSONStringFromDictionary(userInfo as! Dictionary<String, Any>)
//            completionHandler(jsString)
//            
//        default:
//            break
//        }
    }
}
