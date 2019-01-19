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
import JGProgressHUD

class OpenedMessageViewController: UIViewController {

    private var message: Message? {
        didSet {
            configureProperties()
        }
    }
    
    private let loadingViewController = LoadingViewController()
    
    private let hud = JGProgressHUD(style: .dark)
    
    var blurredEffectView = UIVisualEffectView()
    var vibrancyEffectView = UIVisualEffectView()
    let blurEffect = UIBlurEffect(style: .dark)
    lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
    
    private let gradientLayer = CAGradientLayer()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .white
        return label
    }()
    
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
        updateView()
        
//        blurredEffectView.frame = view.bounds
//        view.addSubview(blurredEffectView)
//        vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
//        vibrancyEffectView.frame = view.bounds
//
//        blurredEffectView.contentView.addSubview(vibrancyEffectView)
//
//
//        hud.show(in: view)
        add(loadingViewController)
        if let mediaURL = message?.mediaURL {
            if message?.messageType == .photo {
                configureImage(URL(string: mediaURL)!)
            } else {
                configure(URL(string: mediaURL)!)
            }
        }
        
        usernameLabel.addShadow()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player?.play()
        
        setupGradientLayer()
        usernameLabel.text = message?.user?.username
        view.bringSubviewToFront(usernameLabel)
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
        
        loadingViewController.remove()
//        self.hud.dismiss()
//        self.blurredEffectView.removeFromSuperview()
//        self.vibrancyEffectView.removeFromSuperview()
    }
    
    func configureImage(_ imageURL: URL) {
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.sd_setImage(with: imageURL) { (_, _, _, _) in
//            self.hud.dismiss()
//            self.blurredEffectView.removeFromSuperview()
//            self.vibrancyEffectView.removeFromSuperview()
            self.loadingViewController.remove()
        }
        
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
        view.addSubviews([imageView, usernameLabel])
        view.addGestureRecognizer(dismissGesture)
        setupConstraints()
        
    }
    
    func setupConstraints() {
        imageView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        usernameLabel.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 24, leftConstant: 24, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
    
    func setupGradientLayer() {
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [-0.1, 0.1, 0.9, 1.1]
        view.layer.addSublayer(gradientLayer)
    }
}
