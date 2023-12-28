//
//  UITextField+Extensions.swift
//  iOSAppSecurityIntroduction
//
//  Created by ndthien01 on 26/12/2023.
//

import Foundation
import UIKit

extension UITextField {
    
    func copyText() {
        AppDelegate.customPasteboard?.string = text
    }
    
     func pasteText() {
        if let string = AppDelegate.customPasteboard?.string {
            text = string
        }
    }
    
    func cutText() {
        AppDelegate.customPasteboard?.string = text
        text = nil
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copy(_:)): 
            copyText()
        case #selector(paste(_:)):
            pasteText()
        case #selector(cut(_:)):
            cutText()
        default: break
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
