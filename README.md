# GestureUnlock
一个简单的手势解锁控件，代码使用Swift编写，目的是学习Swift语言，熟悉Swift语法及代码风格

不足之处，望多多指点


![](https://github.com/Hello-Bye/GestureUnlock/blob/master/QQ20171103-141714-HD.gif)

## Use
* 使用很简单，下载demo，将GestureUnlock文件夹拖到自己的项目中，直接调用GesturePasswordViewController即可，自动判断是需要创建还是需要验证，用户自己管理是否需要手势验证操作，详情参考demo

AppDelegate:
```
func applicationDidEnterBackground(_ application: UIApplication) {
        /// 进入后台 记录当前时间
        let currentDate = Date().timeIntervalSince1970
        UserDefaults.standard.set(currentDate, forKey: "geture_lastEnterBackgroundDate")
        UserDefaults.standard.synchronize()
}
```

```
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
```

* 清除手势：

```
GesturePasswordViewController.clearGesturePassword()
```
* 修改密码：

```
let gpvc = GesturePasswordViewController() 
gpvc.isChangeGesture = true
self.present(gpvc, animated: true, completion: nil)
```

* 创建/验证：

```
let gpvc = GesturePasswordViewController()
self.present(gpvc, animated: true, completion: nil)
```



