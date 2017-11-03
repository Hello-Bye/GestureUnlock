//
//  ViewController.swift
//  GestureUnlockDemo
//
//  Created by GeekZooStudio on 2017/11/2.
//  Copyright © 2017年 personal. All rights reserved.
//

import UIKit

let gestureUnlockSwitchStateCacheKey = "gestureUnlockSwitchStateCacheKey"

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureUnlockSwitchState = UserDefaults.standard.object(forKey: gestureUnlockSwitchStateCacheKey) as? Bool
        self.gestureUnlockSwitch.setOn(gestureUnlockSwitchState ?? false, animated: false)
    }
    
    // 开启/关闭手势验证操作，由用户处理
    @IBOutlet weak var gestureUnlockSwitch: UISwitch!
    @IBAction func gestureUnlockSwitchValueChanged(_ sender: UISwitch) {
        
        let gpvc = GesturePasswordViewController()
        gpvc.gestureFinished = { (isCancel) in
            if isCancel {
                sender.setOn(!sender.isOn, animated: true)
            } else {
                sender.setOn(sender.isOn, animated: true)
                UserDefaults.standard.set(sender.isOn, forKey: gestureUnlockSwitchStateCacheKey)
                UserDefaults.standard.synchronize()
            }
        }
        gpvc.onForgotPassword = {(complete) in
            // TODO: 忘记密码
            complete()
        }
        self.present(gpvc, animated: true, completion: nil)
    }
    
    @IBAction func clearGesturePasswordBtnAction(_ sender: UIButton) {
        let alertController = UIAlertController.init(title: "清除手势密码", message: "确定清除手势密码？", preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction.init(title: "取消", style: UIAlertActionStyle.cancel, handler: nil))
        
        alertController.addAction(UIAlertAction.init(title: "确定", style: UIAlertActionStyle.destructive) { (action) in
            GesturePasswordViewController.clearGesturePassword()
            self.gestureUnlockSwitch.setOn(false, animated: true)
            UserDefaults.standard.set(self.gestureUnlockSwitch.isOn, forKey: gestureUnlockSwitchStateCacheKey)
            UserDefaults.standard.synchronize()
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changeGesturePasswordBtnAction(_ sender: UIButton) {
        let gpvc = GesturePasswordViewController()
        gpvc.isChangeGesture = true
        gpvc.gestureFinished = { (isCancel) in
            
        }
        gpvc.onForgotPassword = {(complete) in
            // TODO: 忘记密码
            complete()
        }
        self.present(gpvc, animated: true, completion: nil)
    }
}

