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
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configurePhoto(_ photoURL: URL) {
        
        self.photoView.imageFromServerURL(photoURL.absoluteString)
        
    }
    
}
