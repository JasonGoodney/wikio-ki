//
//  ViewMessageCell.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD

class ViewMessageCell: UICollectionViewCell, ReuseIdentifiable {
    
    private let gradientLayer = CAGradientLayer()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .white
        label.addShadow()
        return label
    }()
    
    var blurredEffectView = UIVisualEffectView()
    var vibrancyEffectView = UIVisualEffectView()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.frame
    }
    
    func configureProperties(with message: Message) {
        usernameLabel.text = message.user?.username
        if let url = URL(string: message.mediaURL ?? "") {
            let hud = JGProgressHUD(style: .dark)
            
            let blurEffect = UIBlurEffect(style: .dark)
            blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.frame = imageView.bounds
            addSubview(blurredEffectView)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = imageView.bounds
            
            //        vibrancyEffectView.contentView.addSubview(hud)
            blurredEffectView.contentView.addSubview(vibrancyEffectView)
            bringSubviewToFront(usernameLabel)
        
            hud.show(in: self)
            
            imageView.sd_setImage(with: url) { (_, _, _, _) in
                
                hud.dismiss()
                self.blurredEffectView.removeFromSuperview()
                self.vibrancyEffectView.removeFromSuperview()
            }
        }
        message.status = .opened
    }
}

// MARK: - UI
private extension ViewMessageCell {
    func updateView() {
        addSubviews(imageView, usernameLabel)
        
       
        
        setupConstraints()
        setupGradientLayer()
        bringSubviewToFront(usernameLabel)
    }
    
    func setupConstraints() {
        imageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        
        usernameLabel.anchor(topAnchor, left: leftAnchor, bottom: nil, right: nil, topConstant: 24, leftConstant: 24, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
    
    func setupGradientLayer() {
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [-0.1, 0.1, 0.9, 1.1]
        layer.addSublayer(gradientLayer)
    }
    
    
}
