//
//  UIView + Ext.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

extension UIView {
    func tAMIC() {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func subviewsOnView(_ subivews: UIView...) {
        subivews.forEach { addSubview($0) }
    }
    
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let vc = responder as? UIViewController {
                return vc
            }
            responder = responder?.next
        }
        return nil
    }
}
