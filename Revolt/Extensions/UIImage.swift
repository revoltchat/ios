//
//  UIImage.swift
//  Revolt
//
//  Created by Angelo on 19/07/2024.
//

import UIKit

extension UIImage {
    enum ContentMode {
        case contentFill
        case contentAspectFill
        case contentAspectFit
    }
    
    func imageWith(newSize size: CGSize, contentMode: ContentMode) -> UIImage? {
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        
        switch contentMode {
            case .contentFill:
                return imageWith(newSize: size)
            case .contentAspectFit:
                let aspectRatio = min(aspectWidth, aspectHeight)
                return imageWith(newSize: CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio))
            case .contentAspectFill:
                let aspectRatio = max(aspectWidth, aspectHeight)
                return imageWith(newSize: CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio))
        }
    }
    
    func imageWith(newSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    var roundedImage: UIImage {
        let rect = CGRect(origin:CGPoint(x: 0, y: 0), size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1)
        defer {
            // End context after returning to avoid memory leak
            UIGraphicsEndImageContext()
        }
        
        UIBezierPath(
            roundedRect: rect,
            cornerRadius: self.size.height
        ).addClip()
        self.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
