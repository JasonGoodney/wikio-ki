//
//  ViewMessageCell.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD
import AVFoundation
import VersaPlayer
import MMPlayerView

class ViewMessageCell: UICollectionViewCell, ReuseIdentifiable {
    
    private let hud = JGProgressHUD(style: .dark)
    let blurEffect = UIBlurEffect(style: .dark)
    lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
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
    private let videoPlayerView = UIView()
    var videoPlayer: AVPlayer?
    var videoPlayerLayer: AVPlayerLayer?
    var paused: Bool = false
    
    //This will be called everytime a new value is set on the videoplayer item
    var videoPlayerItem: AVPlayerItem? = nil {
        didSet {
            /*
             If needed, configure player item here before associating it with a player.
             (example: adding outputs, setting text style rules, selecting media options)
             */
            videoPlayer?.replaceCurrentItem(with: self.videoPlayerItem)
        }
    }
    
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
//            let hud = JGProgressHUD(style: .dark)
            
//            let blurEffect = UIBlurEffect(style: .dark)
//            blurredEffectView = UIVisualEffectView(effect: blurEffect)
            //            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            
            
            blurredEffectView.frame = self.bounds
            addSubview(blurredEffectView)
            vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = self.bounds
            
            blurredEffectView.contentView.addSubview(vibrancyEffectView)
            bringSubviewToFront(usernameLabel)
            
            hud.show(in: self)
            
            if message.messageType == .photo {

                self.imageView.sd_setImage(with: url) { (_, _, _, _) in
                
                    self.hud.dismiss()
                    self.blurredEffectView.removeFromSuperview()
                    self.vibrancyEffectView.removeFromSuperview()
                }
            } else {
                videoPlayerItem = AVPlayerItem(url: url)
                setupMoviePlayer()
                self.hud.dismiss()
                self.blurredEffectView.removeFromSuperview()
                self.vibrancyEffectView.removeFromSuperview()
                startPlayback()
            }
        }
        message.status = .opened
    }

    func stopPlayback(){
        self.videoPlayer?.pause()
    }
    
    func startPlayback(){
        self.videoPlayer?.play()
    }
}

// MARK: - UI
private extension ViewMessageCell {
    func updateView() {
        addSubviews([imageView, usernameLabel, videoPlayerView])
        setupConstraints()
        setupGradientLayer()
        bringSubviewToFront(usernameLabel)
    }
    
    func setupConstraints() {
        imageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        videoPlayerView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        
        usernameLabel.anchor(topAnchor, left: leftAnchor, bottom: nil, right: nil, topConstant: 24, leftConstant: 24, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
    
    func setupGradientLayer() {
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [-0.1, 0.1, 0.9, 1.1]
        layer.addSublayer(gradientLayer)
    }
    
    func setupMoviePlayer(){
        self.videoPlayer = AVPlayer.init(playerItem: self.videoPlayerItem)
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPlayer?.volume = 3
        videoPlayer?.actionAtItemEnd = .none
//        
//        //        You need to have different variations
//        //        according to the device so as the avplayer fits well
//        if UIScreen.main.bounds.width == 375 {
//            let widthRequired = self.frame.size.width - 20
//            videoPlayerLayer?.frame = CGRect.init(x: 0, y: 0, width: widthRequired, height: widthRequired/1.78)
//        }else if UIScreen.main.bounds.width == 320 {
//            videoPlayerLayer?.frame = CGRect.init(x: 0, y: 0, width: (self.frame.size.height - 120) * 1.78, height: self.frame.size.height - 120)
//        }else{
//            let widthRequired = self.frame.size.width
//            videoPlayerLayer?.frame = CGRect.init(x: 0, y: 0, width: widthRequired, height: widthRequired/1.78)
//        }
        videoPlayerLayer?.frame = UIScreen.main.bounds
        self.backgroundColor = .clear
        self.videoPlayerView.layer.insertSublayer(videoPlayerLayer!, at: 0)
        
        // This notification is fired when the video ends, you can handle it in the method.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemDidReachEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: videoPlayer?.currentItem)
    }
    
    // A notification is fired and seeker is sent to the beginning to loop the video again
    @objc func playerItemDidReachEnd(notification: Notification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: .zero) { (success) in
            if success {
                print("🤶\(#function)")
            }
        }
    }
}
