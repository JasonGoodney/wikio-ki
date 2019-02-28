//
//  SendToPreviewViewCell.swift
//  picture
//
//  Created by Jason Goodney on 2/27/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import AVKit

class SendToPreviewViewCell: UITableViewCell, ReuseIdentifiable {

    // MARK: - Views
    private let photoView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private var videoView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    var player: AVPlayer?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configurePhoto(_ image: UIImage, size: CGSize) {
        addSubview(photoView)
        photoView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        photoView.image = image
    }
    
    func configureVideo(_ videoURL: URL, _ image: UIImage) {
        addSubview(videoView)

        videoView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        
        videoView.layer.cornerRadius = 12
        let playerItem = CachingPlayerItem(url: videoURL, customFileExtension: "mp4")
        self.player = AVPlayer(playerItem: playerItem)
        
        player?.automaticallyWaitsToMinimizeStalling = false
        let videoLayer = AVPlayerLayer(player: self.player)
        videoLayer.frame = bounds
        videoLayer.videoGravity = .resizeAspect
        self.videoView.layer.addSublayer(videoLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        
        // Allow background audio to continue to play
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, mode: .default, options: [])
            } else {
            }
        } catch let error as NSError {
            print(error)
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error)
        }
        
        
        videoView.addSubview(photoView)
        photoView.image = image
        
        photoView.anchor(top: videoView.topAnchor, leading: videoView.leadingAnchor, bottom: videoView.bottomAnchor, trailing: videoView.trailingAnchor)
        
        photoView.clipsToBounds = true
        
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        playFromBeginning()
    }
    
    func playFromBeginning() {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    func pause() {
        if self.player != nil {
            player?.pause()
        }
    }

}
