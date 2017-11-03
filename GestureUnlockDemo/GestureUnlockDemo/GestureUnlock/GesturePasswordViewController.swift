//
//  GesturePasswordViewController.swift
//  GoAheadAndPlay
//
//  Created by GeekZooStudio on 2017/11/1.
//  Copyright © 2017年 personal. All rights reserved.
//

import UIKit

class GesturePasswordViewController: UIViewController, GesturePasswordViewDelegate {
    
    // 手势验证成功闭包
    var gestureFinished: ((_ isCancel: Bool) -> Void)?
    // 忘记密码闭包
    var onForgotPassword: ((()->Void) -> Void)?
    // 是修改手势
    var isChangeGesture = false
    // 取消按钮
    let cancelBtn = UIButton.init(type: UIButtonType.custom)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.presentingViewController != nil {
            self.cancelBtn.isHidden = false
        } else {
            self.cancelBtn.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1.0)
        
        let gesturePasswordView = GesturePasswordView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width))
        gesturePasswordView.center = CGPoint(x: self.view.frame.width / 2.0, y: self.view.frame.height / 2.0)
        gesturePasswordView.backgroundColor = self.view.backgroundColor
        gesturePasswordView.delegate = self
        gesturePasswordView.isChangeGesture = self.isChangeGesture
        self.view.addSubview(gesturePasswordView)
        
        self.view.addSubview(self.cancelBtn)
        self.cancelBtn.setTitle("取消", for: UIControlState.normal)
        self.cancelBtn.setTitleColor(UIColor.black, for: UIControlState.normal)
        self.cancelBtn.frame = CGRect(x: 20, y: 44, width: 50, height: 44)
        self.cancelBtn.addTarget(self, action: #selector(cancelBtnClick(_:)), for: UIControlEvents.touchUpInside)
    }
    
    @objc func cancelBtnClick(_ btn: UIButton) {
        self.gestureFinished?(true)
        self.onBack()
    }
    
    func onBack() {
        if self.presentingViewController == nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /**
     *  清除手势密码
     */
    class func clearGesturePassword() {
        GesturePasswordView().clearCachePassword()
    }
    
    // MARK: 手势密码绘制结束代理方法
    func didDrawGesturePassword(_ GesturePasswordView: GesturePasswordView, _ password: String, _ gestureVerifyResult: GesturePasswordVerifyResult, _ gesturePasswordViewType: GesturePasswordViewType) {
        if gestureVerifyResult == GesturePasswordVerifyResult.createSuccessful ||
            (gestureVerifyResult == GesturePasswordVerifyResult.verifySuccessful && gesturePasswordViewType != GesturePasswordViewType.change) {
            
            self.gestureFinished?(false)
            self.onBack()
        }
    }
    
    func forgotGesture(_ GesturePasswordView: GesturePasswordView, _ complete: () -> Void) {
        self.onForgotPassword?(complete)
    }
}
