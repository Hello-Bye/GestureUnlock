//
//  AppDelegate.swift
//  GestureUnlockDemo
//
//  Created by GeekZooStudio on 2017/11/2.
//  Copyright © 2017年 personal. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        /// 进入后台 记录当前时间
        let currentDate = Date().timeIntervalSince1970
        UserDefaults.standard.set(currentDate, forKey: "geture_lastEnterBackgroundDate")
        UserDefaults.standard.synchronize()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        /// 进入前台, 如果距离上次进入后台时间间隔大于1分钟，就要求验证手势
        let gestureUnlockSwitchState = UserDefaults.standard.object(forKey: gestureUnlockSwitchStateCacheKey) as? Bool
        if gestureUnlockSwitchState ?? false {
            let lastEnterBackgroundDate = UserDefaults.standard.object(forKey: "geture_lastEnterBackgroundDate") as? TimeInterval
            let currentDate = Date().timeIntervalSince1970
            let timeInterval = currentDate - (lastEnterBackgroundDate ?? 0)
            if timeInterval > 60 {
                self.verifyGesture()
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    /**
     *  验证手势
     */
    func verifyGesture() {
        let gpvc = GesturePasswordViewController()
        gpvc.gestureFinished = { (isCancel) in
            self.gotoHome()
        }
        gpvc.onForgotPassword = { (complete) in
            // TODO:
            complete()
        }
        self.window?.rootViewController = gpvc
    }
    
    func gotoHome() {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateInitialViewController() as? ViewController
        self.window?.rootViewController = vc
    }
    
}

