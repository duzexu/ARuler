//
//  UIColorExt.swift
//  ARuler
//
//  Created by duzexu on 2017/9/21.
//  Copyright © 2017年 duzexu. All rights reserved.
//

import Foundation

extension UIColor {
    class var textColor: UIColor {
        get {
            return UIColor(red: 88/255.0, green: 88/255.0, blue: 88/255.0, alpha: 1)
        }
    }
    
    class var headerTextColor: UIColor {
        get {
            return UIColor(red: 167/255.0, green: 180/255.0, blue: 190/255.0, alpha: 1)
        }
    }
    
    class var themeColor: UIColor {
        get {
            return UIColor(red: 59/255.0, green: 122/255.0, blue: 219/255.0, alpha: 1)
        }
    }
    
    class var alertColor: UIColor {
        get {
            return UIColor(red: 223/255.0, green: 53/255.0, blue: 46/255.0, alpha: 1)
        }
    }
    
    class var fineColor: UIColor {
        get {
            return UIColor(red: 149/255.0, green: 210/255.0, blue: 107/255.0, alpha: 1)
        }
    }
}
