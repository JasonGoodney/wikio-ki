//
//  ImageProcessor.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

struct ImageProcessor: MediaProcessable {
    
    func addOverlay(_ overlay: UITextField, to image: UIImage, size: CGSize) -> UIImage {
        let width = size.width
        let height = size.height
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 2.0)
        let currentView = UIView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let currentImage = UIImageView.init(image: image)
        currentImage.frame = CGRect(x: 0, y: 0, width: width, height: height)
        currentView.addSubview(currentImage)
        currentView.addSubview(overlay)
        currentView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
