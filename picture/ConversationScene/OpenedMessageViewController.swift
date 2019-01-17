//
//  OpenedMessageViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class OpenedMessageViewController: UIViewController {

    private var message: Message? {
        didSet {
            configureProperties()
        }
    }
    
    var player: AVPlayer?
    var playerController : AVPlayerViewController?
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var dismissGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(dismissGestureTapped(_:)))
        return gesture
    }()
    
    init(message: Message) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mediaURL = message?.mediaURL {
            if message?.messageType == .photo {
                configureImage(URL(string: mediaURL)!)
            } else {
                configure(URL(string: mediaURL)!)
            }
        }
        
        updateView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player?.play()
    }
    
    func configure(_ videoURL: URL) {
        player = AVPlayer(url: videoURL)
        playerController = AVPlayerViewController()
        
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = false
        
        playerController!.player = player!
        self.addChild(playerController!)
        self.view.addSubview(playerController!.view)
        playerController!.view.frame = view.frame
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
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
    }
    
    func configureImage(_ imageURL: URL) {
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.sd_setImage(with: imageURL)
        
    }
    
    @objc func dismissGestureTapped(_ recognizer: UITapGestureRecognizer) {
        dismiss(animated: false) {
            DispatchQueue.main.async {
                
                self.message?.status = .opened
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }

}

// MARK: - UI
private extension OpenedMessageViewController {
    func configureProperties() {
        guard let message = message, let imageURL = URL(string: message.mediaURL!) else { return }
        imageView.sd_setImage(with: imageURL)
        message.isOpened = true
    }
    
    func updateView() {
        view.backgroundColor = .white
        view.addSubviews(imageView)
        view.addGestureRecognizer(dismissGesture)
        setupConstraints()
    }
    
    func setupConstraints() {
        imageView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
}
