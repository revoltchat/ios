//
//  UIFont.swift
//  Revolt
//
//  Created by Angelo on 10/11/2024.
//

import UIKit

extension UIFont {
    func bottomOffsetFromBaselineForVerticalCentering(targetHeight height: CGFloat) -> CGFloat {
        let textHeight = ascender - descender
        let offset = (textHeight - height) / 2 + descender
        return offset
    }
}
