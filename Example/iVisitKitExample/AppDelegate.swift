//
//  AppDelegate.swift
//  iVisitKitExample
//
//  Created by CocoaBob on 2019-01-05.
//  Copyright © 2019 CocoaBob. All rights reserved.
//

import UIKit
import iVisitKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let url = Bundle.main.url(forResource: "demo", withExtension: "pno") else {
            return false
        }
        
        self.window = UIWindow()
        
        IVDocumentManager.shared().currentOpeningDocument = IVDocumentManager.loadDocument(url.path)
        IVDocumentManager.shared().currentOpeningDocument.open()
        self.window?.rootViewController = UINavigationController(rootViewController: IVPanoramaViewController.shared())
        self.window?.makeKeyAndVisible()
        
        return true
    }
}

