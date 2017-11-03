//
//  GesturePasswordView.swift
//  GoAheadAndPlay
//
//  Created by GeekZooStudio on 2017/11/1.
//  Copyright © 2017年 personal. All rights reserved.
//

import UIKit

/// 贝塞尔路径颜色
let BezierPathColor = UIColor.init(red: 60.0/255, green: 142.0/255, blue: 215.0/255, alpha: 1.0)
/// btn tag基础常量, tag最好不要直接从0开始, 0-100为系统保留值
let tagConst = 1000


enum GesturePasswordViewType {
    /// 创建手势
    case create
    /// 验证手势
    case verify
    /// 修改手势
    case change
}

enum GesturePasswordVerifyResult {
    /// 空
    case none
    /// 验证
    case verify
    /// 验证成功
    case verifySuccessful
    /// 验证失败
    case verifyFailed
    /// 绘制手势
    case create
    /// 再次绘制手势
    case createConfirm
    /// 两次绘制不一样
    case createErrorNotSame
    /// 密码长度错误
    case createErrorLength
    /// 绘制手势成功
    case createSuccessful
}

/// 代理协议  加了class的protocol才能被使用在类的delegate模式中,因为protocol不加class标记则还可以被enum,struct实现
protocol GesturePasswordViewDelegate: class {
    func didDrawGesturePassword(_ GesturePasswordView: GesturePasswordView, _ password: String, _ gestureVerifyResult: GesturePasswordVerifyResult, _ gesturePasswordViewType: GesturePasswordViewType)
    func forgotGesture(_ GesturePasswordView: GesturePasswordView, _ complete: () -> Void)
}

/// class
class GesturePasswordView: UIView {

//    private lazy var redrawBtn = UIButton.init(type: UIButtonType.custom) // 懒加载简单写法
    private lazy var redrawBtn = { () -> UIButton in
        var redraw = UIButton.init(type: UIButtonType.custom)
        redraw.setTitle("重绘手势", for: UIControlState.normal)
        redraw.setTitleColor(UIColor.black, for: UIControlState.normal)
        redraw.frame = CGRect.init(x: (self.frame.width - 100) / 2.0, y: self.frame.height - 20, width: 100, height: 20)
        redraw.addTarget(self, action: #selector(redrawBtnClick), for: UIControlEvents.touchUpInside)
        return redraw
    }() // 懒加载完整写法，好处是可以进行初始化
    
    private lazy var forgotBtn = { () -> UIButton in
        var forgot = UIButton.init(type: UIButtonType.custom)
        forgot.setTitle("忘记密码", for: UIControlState.normal)
        forgot.setTitleColor(UIColor.black, for: UIControlState.normal)
        forgot.frame = CGRect.init(x: (self.frame.width - 100) / 2.0, y: self.frame.height - 20, width: 100, height: 20)
        forgot.addTarget(self, action: #selector(forgotBtnClick), for: UIControlEvents.touchUpInside)
        return forgot
    }() // 懒加载完整写法，好处是可以进行初始化
    
    private var stateTipsLabel:UILabel = UILabel.init()
    
    private var gestureDot:[UIButton] = []
    
    private var selectedDot:[UIButton] = []
    
    private var currentTouchPoint:CGPoint = CGPoint.zero
    
    private var passwordVerifyResult = GesturePasswordVerifyResult.none
    
    private var lastPassword = ""
    
    private var gesturePasswordType = GesturePasswordViewType.create
    
    private var needDelayClearPath = false
    
    private var gestureFinished = false
    
    var _isChangeGesture = false
    var isChangeGesture:Bool {
        set {
            _isChangeGesture = newValue
            if _isChangeGesture { // 修改
                self.gesturePasswordType = GesturePasswordViewType.change
                self.passwordVerifyResult = GesturePasswordVerifyResult.verify
            }
        }
        get {
            return _isChangeGesture
        }
    }
    
    var gestureMinLength = 4
    
    var delegate:GesturePasswordViewDelegate?
    
    
    // 构造方法
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.custom()
    }
    
    // 重写布局，在这个方法里view.frame才是最正确的
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stateTipsLabel.frame = CGRect.init(x: 0, y: 0, width: self.frame.width, height: 22)
        
        let margin:CGFloat = 50.0
        let contentWidth = self.frame.width - margin * 2
        let btnWidth = (contentWidth - margin * 2) / 3.0
        let startY = (self.frame.height - contentWidth) / 2.0
        
        for btn in self.gestureDot {
            let tag = btn.tag - tagConst
            let btnX = CGFloat(tag % 3) * (btnWidth + margin) + margin
            let btnY = CGFloat(tag / 3) * (btnWidth + margin) + startY
            
            btn.frame = CGRect.init(x: btnX, y: btnY, width: btnWidth, height: btnWidth)
            
            btn.setImage(#imageLiteral(resourceName: "pvg19_radio_nor.png").scaleSize(btn.frame.size), for: UIControlState.normal)
            btn.setImage(#imageLiteral(resourceName: "pvg19_radio_sel.png").scaleSize(btn.frame.size), for: UIControlState.selected)
            
            btn.layer.cornerRadius = btnWidth / 2.0
            btn.layer.masksToBounds = true
        }
    }
    
    /// 自定义操作
    private func custom() {
        self.backgroundColor = UIColor.white
        
        // 滑动手势
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureChange(gesture:)))
        self.addGestureRecognizer(panGesture)
        
        // 提示label
        self.addSubview(self.stateTipsLabel)
        self.stateTipsLabel.font = UIFont.systemFont(ofSize: 18)
        self.stateTipsLabel.textColor = UIColor.black
        self.stateTipsLabel.textAlignment = NSTextAlignment.center
        
        // 创建手势按钮
        for i in 0..<9 {
            let btn = UIButton.init(type: UIButtonType.custom)
            btn.tag = tagConst + i
            btn.isUserInteractionEnabled = false
            btn.backgroundColor = self.backgroundColor
            self.gestureDot.append(btn)
            self.addSubview(btn)
        }
        
        // 默认type
        if self.getCachePassword() == nil { // 创建
            self.gesturePasswordType = GesturePasswordViewType.create
            self.passwordVerifyResult = GesturePasswordVerifyResult.create
        } else { // 验证
            self.gesturePasswordType = GesturePasswordViewType.verify
            self.passwordVerifyResult = GesturePasswordVerifyResult.verify
        }
        
        self.showTips(self.passwordVerifyResult)
    }
    
    /// 手势事件
    @objc func panGestureChange(gesture: UIPanGestureRecognizer) {
        let state = gesture.state
        // 手势开始
        if state == UIGestureRecognizerState.began {
            self.clearPath()
            self.needDelayClearPath = false
        }
        
        // 记录当前touch点
        self.currentTouchPoint = gesture.location(in: self)
        self.setNeedsDisplay()
        
        // 遍历找出选中的btn
        for btn in self.gestureDot {
            if btn.frame.contains(self.currentTouchPoint) && btn.isSelected == false {
                btn.isSelected = true
                self.selectedDot.append(btn)
            }
        }
        
        // 手势结束
        if state == UIGestureRecognizerState.ended {
            
            if self.gesturePasswordType == GesturePasswordViewType.create { // 创建手势
                if self.passwordVerifyResult == GesturePasswordVerifyResult.create {
                    // 第一次, 先判断长度
                    if self.currentPassword().characters.count < self.gestureMinLength {
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createErrorLength
                    } else {
                        self.lastPassword = self.currentPassword()
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createConfirm
                    }
                    
                } else if self.passwordVerifyResult == GesturePasswordVerifyResult.createConfirm {
                    // 第二次， 先判断和上一次绘制的手势是否一样
                    if self.currentPassword() != self.lastPassword {
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createErrorNotSame
                    } else {
                        // 保存手势
                        self.cachePassword()
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createSuccessful
                    }
                }
            } else if self.gesturePasswordType == GesturePasswordViewType.verify { // 验证手势
                // 验证
                if self.verifyPassword() {
                    self.passwordVerifyResult = GesturePasswordVerifyResult.verifySuccessful
                } else {
                    self.passwordVerifyResult = GesturePasswordVerifyResult.verifyFailed
                }
            } else if self.gesturePasswordType == GesturePasswordViewType.change { // 修改手势
                // 先进行验证
                if self.passwordVerifyResult == GesturePasswordVerifyResult.verify {
                    if self.verifyPassword() {
                        self.passwordVerifyResult = GesturePasswordVerifyResult.create
                    } else {
                        self.passwordVerifyResult = GesturePasswordVerifyResult.verifyFailed
                    }
                } else if self.passwordVerifyResult == GesturePasswordVerifyResult.create {
                    // 创建新手势, 先判断长度
                    if self.currentPassword().characters.count < self.gestureMinLength {
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createErrorLength
                    } else {
                        self.lastPassword = self.currentPassword()
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createConfirm
                    }
                    
                } else if self.passwordVerifyResult == GesturePasswordVerifyResult.createConfirm {
                    // 创建新手势确认， 先判断和上一次绘制的手势是否一样
                    if self.currentPassword() != self.lastPassword {
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createErrorNotSame
                    } else {
                        // 保存手势
                        self.cachePassword()
                        self.passwordVerifyResult = GesturePasswordVerifyResult.createSuccessful
                    }
                }
            }
            
            self.delegate?.didDrawGesturePassword(self, self.currentPassword(), self.passwordVerifyResult, self.gesturePasswordType)
            
            self.showTips(self.passwordVerifyResult)
            
            self.gestureFinished = true
            
            self.setNeedsDisplay()
            
            self.needDelayClearPath = true
            
            // 延迟0.5秒清空手势
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                if self.needDelayClearPath { // 如果 needDelayClearPath == false 说明已经清空过了，不需要再次清空
                    self.clearPath()
                }
            })
        }
    }
    
    /// 重新绘制，每次来这个方法都会清空重绘
    override func draw(_ rect: CGRect) {
        if self.selectedDot.count <= 0 {
            return
        }
        
        let path = UIBezierPath.init()
        
        for btn in self.selectedDot {
            if btn == self.selectedDot[0] {
                path.move(to: btn.center)
            } else {
                path.addLine(to: btn.center)
            }
        }
        
        if self.gestureFinished {
            switch self.passwordVerifyResult {
            case .createErrorLength, .createErrorNotSame, .verifyFailed:
                UIColor.red.set()
                break
            default:
                BezierPathColor.set()
                break
            }
            
        } else {
            path.addLine(to: self.currentTouchPoint)
            BezierPathColor.set()
        }
        
        path.lineWidth = 5.0
        path.lineCapStyle = CGLineCap.round
        path.lineJoinStyle = CGLineJoin.round
        path.stroke()
    }
    
    /// 重画手势
    @objc private func redrawBtnClick() {
        self.clearPath()
        self.lastPassword = ""
        
        if self.gesturePasswordType == GesturePasswordViewType.create ||
            self.gesturePasswordType == GesturePasswordViewType.change {
            
            self.passwordVerifyResult = GesturePasswordVerifyResult.create
            
        } else if self.gesturePasswordType == GesturePasswordViewType.verify {
            
            self.passwordVerifyResult = GesturePasswordVerifyResult.verify
        }
        self.showTips(self.passwordVerifyResult)
    }
    
    @objc private func forgotBtnClick() {
        // 闭包
        let complete = { () -> Void in
            self.clearCachePassword()
            self.lastPassword = ""
            self.clearPath()
            
            self.gesturePasswordType = GesturePasswordViewType.create
            self.passwordVerifyResult = GesturePasswordVerifyResult.create
            
            self.showTips(self.passwordVerifyResult)
        }
        // 通知代理 忘记密码
        self.delegate?.forgotGesture(self, complete)
    }
    
    /// 清空绘制的密码
    func clearPath() {
        for btn in self.selectedDot {
            btn.isSelected = false
        }
        self.selectedDot.removeAll()
        
        self.gestureFinished = false
        
        self.setNeedsDisplay()
    }
    
    /// 验证密码是否正确
    func verifyPassword() -> Bool {
        return self.currentPassword() == self.getCachePassword()
    }
    
    /// 显示验证结果提示文字
    func showTips(_ result: GesturePasswordVerifyResult) {
        
        if self.gesturePasswordType == GesturePasswordViewType.change {
            switch result {
            case .none:
                self.stateTipsLabel.text = ""
                self.stateTipsLabel.textColor = UIColor.clear
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .verify:
                self.stateTipsLabel.text = "验证您的手势"
                self.stateTipsLabel.textColor = UIColor.black
                self.redrawBtn.removeFromSuperview()
                self.addSubview(self.forgotBtn)
                break
            case .verifyFailed:
                self.stateTipsLabel.text = "手势验证失败"
                self.stateTipsLabel.textColor = UIColor.red
                self.shakeAnimation()
                self.redrawBtn.removeFromSuperview()
                self.addSubview(self.forgotBtn)
                // 验证失败需要重置状态为需要验证状态
                self.passwordVerifyResult = GesturePasswordVerifyResult.verify
                break
            case .create:
                self.stateTipsLabel.text = "创建新的手势"
                self.stateTipsLabel.textColor = UIColor.black
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .createConfirm:
                self.stateTipsLabel.text = "确认新的手势"
                self.stateTipsLabel.textColor = UIColor.black
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .createErrorNotSame:
                self.stateTipsLabel.text = "两次手势不一样"
                self.stateTipsLabel.textColor = UIColor.red
                self.shakeAnimation()
                self.addSubview(self.redrawBtn)
                self.forgotBtn.removeFromSuperview()
                
                self.passwordVerifyResult = GesturePasswordVerifyResult.createConfirm
                break
            case .createErrorLength:
                self.stateTipsLabel.text = "手势至少需要4个点"
                self.stateTipsLabel.textColor = UIColor.red
                self.shakeAnimation()
                self.addSubview(self.redrawBtn)
                self.forgotBtn.removeFromSuperview()
                
                self.passwordVerifyResult = GesturePasswordVerifyResult.create
                break
            case .createSuccessful:
                self.stateTipsLabel.text = "新的手势创建成功"
                self.stateTipsLabel.textColor = BezierPathColor
                self.shakeAnimation()
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            default:
                break
            }
        } else {
            switch result {
            case .none:
                self.stateTipsLabel.text = ""
                self.stateTipsLabel.textColor = UIColor.clear
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .verify:
                self.stateTipsLabel.text = "验证您的手势"
                self.stateTipsLabel.textColor = UIColor.black
                self.redrawBtn.removeFromSuperview()
                self.addSubview(self.forgotBtn)
                break
            case .verifySuccessful:
                self.stateTipsLabel.text = "手势验证成功"
                self.stateTipsLabel.textColor = BezierPathColor
                self.shakeAnimation()
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .verifyFailed:
                self.stateTipsLabel.text = "手势验证失败"
                self.stateTipsLabel.textColor = UIColor.red
                self.shakeAnimation()
                self.redrawBtn.removeFromSuperview()
                self.addSubview(self.forgotBtn)
                
                self.passwordVerifyResult = GesturePasswordVerifyResult.verify
                break
            case .create:
                self.stateTipsLabel.text = "创建您的手势"
                self.stateTipsLabel.textColor = UIColor.black
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .createConfirm:
                self.stateTipsLabel.text = "再次创建您的手势"
                self.stateTipsLabel.textColor = UIColor.black
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            case .createErrorNotSame:
                self.stateTipsLabel.text = "两次手势不一样"
                self.stateTipsLabel.textColor = UIColor.red
                self.shakeAnimation()
                self.addSubview(self.redrawBtn)
                self.forgotBtn.removeFromSuperview()
                
                self.passwordVerifyResult = GesturePasswordVerifyResult.createConfirm
                break
            case .createErrorLength:
                self.stateTipsLabel.text = "手势至少需要4个点"
                self.stateTipsLabel.textColor = UIColor.red
                self.shakeAnimation()
                self.addSubview(self.redrawBtn)
                self.forgotBtn.removeFromSuperview()
                
                self.passwordVerifyResult = GesturePasswordVerifyResult.create
                break
            case .createSuccessful:
                self.stateTipsLabel.text = "手势创建成功"
                self.stateTipsLabel.textColor = BezierPathColor
                self.shakeAnimation()
                self.redrawBtn.removeFromSuperview()
                self.forgotBtn.removeFromSuperview()
                break
            }
        }
    }
    
    /// 显示提示文字抖动动画
    func shakeAnimation() {
        let viewLayer = self.stateTipsLabel.layer
        let position = viewLayer.position
        let left = CGPoint(x: position.x - 10, y: position.y)
        let right = CGPoint(x: position.x + 10, y: position.y)
        
        let animation = CABasicAnimation.init(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.fromValue = NSValue.init(cgPoint: left)
        animation.toValue = NSValue.init(cgPoint: right)
        animation.autoreverses = true
        animation.duration = CFTimeInterval(0.08)
        animation.repeatCount = Float(3)
        
        viewLayer.add(animation, forKey: nil)
    }
    
    /// 获取当前绘制的密码
    func currentPassword() -> String {
        var currentPassword = ""
        for btn in self.selectedDot {
            let tag = btn.tag - tagConst
            currentPassword += String(tag)
        }
        return currentPassword
    }
    
    /// 保存当前绘制的密码
    func cachePassword() {
        UserDefaults.standard.set(self.currentPassword(), forKey: "zl_gesturePasswordCacheKey")
        UserDefaults.standard.synchronize()
    }
    
    /// 获取缓存的密码
    func getCachePassword() -> String? {
        let password = UserDefaults.standard.object(forKey: "zl_gesturePasswordCacheKey")
        return password as? String
    }
    
    /// 清除缓存的密码
    func clearCachePassword() {
        UserDefaults.standard.removeObject(forKey: "zl_gesturePasswordCacheKey")
        UserDefaults.standard.synchronize()
    }
}

///  UIImage category ====================
extension UIImage {
    
    open func scaleSize(_ size: CGSize!) -> UIImage! {
        
        UIGraphicsBeginImageContext(size)
        
        self.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
}
