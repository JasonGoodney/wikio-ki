//
//  MediaProcessable.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import AVKit

protocol MediaProcessable {
    func addOverlay(_ overlay: UIView, to image: UIImage, size: CGSize) -> UIImage
    func addOverlay(_ overlay: UIView, to video: AVAsset, size: CGSize) -> AVAsset
}

extension MediaProcessable {
    func addOverlay(_ overlay: UIView, to image: UIImage, size: CGSize) -> UIImage {
        // Optional
        return UIImage()
    }
    
    func addOverlay(_ overlay: UIView, to video: AVAsset, size: CGSize) -> AVAsset {
        // Optional
        return AVAsset()
    }
}
