//
//  UIImage+Rotate.swift
//  picture
//
//  Created by Jason Goodney on 1/22/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.x, y: -origin.y,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return rotatedImage ?? self
        }
        
        return self
    }
    
    func addOverlay(_ overlay: UIView, size: CGSize) -> UIImage {
        let width = size.width
        let height = size.height
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 2.0)
        let currentView = UIView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let currentImage = UIImageView.init(image: self)
        currentImage.frame = CGRect(x: 0, y: 0, width: width, height: height)
        currentView.addSubview(currentImage)
        currentView.addSubview(overlay)
        currentView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
