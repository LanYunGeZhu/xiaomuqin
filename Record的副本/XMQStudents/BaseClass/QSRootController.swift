//
//  QSRootController.swift
//  XMQSeacher
//
//  Created by bin xie on 2019/9/19.
//  Copyright © 2019 小木琴. All rights reserved.
//

import UIKit

class QSRootController: NSObject {

    static func chooseRootController(window: UIWindow) {
        
        let rootNav = UINavigationController.init(rootViewController: ViewController())
        window.rootViewController = rootNav
    }
}
