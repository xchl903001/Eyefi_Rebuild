//
//  EyefiApp.swift
//  EyeFi
//
//  Created by admin on 2022/8/24.
//

import Foundation
import UIKit
class EyefiApp {
    
   class var keywindow:UIWindow? {
        get {
           return EyefiApp.getKeyWindow()
        }
    }
    
   class var statusBarHeight:CGFloat {
        get {
            return EyefiApp.getStatusBarHeight()
        }
    }
    
    class var isNotchScreen:Bool {
        get {
           return getStatusBarHeight() > 20
        }
    }
    
    // get the keywindow for current app
    private class  func getKeyWindow() -> UIWindow? {
        for scence in UIApplication.shared.connectedScenes {
            if scence is UIWindowScene {
                let windowScence = scence as! UIWindowScene
                for window in windowScence.windows {
                    if window.isKeyWindow {
                        return window
                    }
                }
            }
        }
        return nil
    }
    
    // get status bar height
    class func getStatusBarHeight() -> CGFloat {
        for scence in UIApplication.shared.connectedScenes {
            if scence is UIWindowScene {
                let windowScence = scence as! UIWindowScene
                return windowScence.statusBarManager?.statusBarFrame.size.height ?? 20
            }
        }
        return 20
    }
}
