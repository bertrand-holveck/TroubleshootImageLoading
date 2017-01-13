//
//  UIViewExtension.swift
//  TroubleshootImageLoading
//
//  Created by Bertrand HOLVECK on 06/01/2017.
//  Copyright © 2017 HOLVECK Ingénieries. All rights reserved.
//

import UIKit

extension UIView {
    func enableAllButtons(_ enable: Bool) {
        for button in (subviews.filter{ $0 is UIButton } as! [UIButton]) {
            button.isEnabled = enable
        }
    }
}
