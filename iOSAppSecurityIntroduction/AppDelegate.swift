//
//  AppDelegate.swift
//  iOSAppSecurityIntroduction
//
//  Created by ndthien01 on 26/12/2023.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    lazy var splashView: UIImageView = {
        let image = UIImageView(frame: window!.frame)
        image.backgroundColor = .white
        return image
    }()

    static var customPasteboard = UIPasteboard(name: .init("CustomPasteboard"), create: true)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        window?.addSubview(splashView)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        splashView.removeFromSuperview()
    }
}

