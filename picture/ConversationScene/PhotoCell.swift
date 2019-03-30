//
//  PhotoCell.swift
//  picture
//
//  Created by Jason Goodney on 2/8/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD
import FirebaseStorage
import Digger

class PhotoCell: UICollectionViewCell, ReuseIdentifiable {
    
    
    private var message: Message?
    private var chatWithFriend: ChatWithFriend?
    
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    private let loadingViewController = LoadingViewController()
    
    private let gradientLayer = CAGradientLayer()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    var photoView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let mediaViews = [photoView]
        addSubviews(mediaViews)
        mediaViews.forEach({
            $0.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        })
        
        photoView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(zoom(gesture:))))
        photoView.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configurePhoto(_ photoURL: URL) {
        
        self.photoView.imageFromServerURL(photoURL.absoluteString)
        
    }
    
    var lastScale:CGFloat!
    @objc func zoom(gesture:UIPinchGestureRecognizer) {
        if(gesture.state == .began) {
            // Reset the last scale, necessary if there are multiple objects with different scales
            lastScale = gesture.scale
        }
        if (gesture.state == .began || gesture.state == .changed) {
            let currentScale = gesture.view!.layer.value(forKeyPath:"transform.scale")! as! CGFloat
            // Constants to adjust the max/min values of zoom
            let kMaxScale:CGFloat = 2.0
            let kMinScale:CGFloat = 1.0
            var newScale = 1 -  (lastScale - gesture.scale)
            newScale = min(newScale, kMaxScale / currentScale)
            newScale = max(newScale, kMinScale / currentScale)
            let transform = (gesture.view?.transform)!.scaledBy(x: newScale, y: newScale);
            gesture.view?.transform = transform
            lastScale = gesture.scale  // Store the previous scale factor for the next pinch gesture call
        }
    }
    
}
