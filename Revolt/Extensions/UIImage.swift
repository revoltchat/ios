//
//  UIImage.swift
//  Revolt
//
//  Created by Angelo on 19/07/2024.
//

import UIKit

extension UIImage {
    func imageWith(newSize: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return image
    }
}
