//
//  CameraViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SwiftyCam

class CameraViewController: SwiftyCamViewController {
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    static func fromStoryboard() -> CameraViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
    }

    private let blurViewController = LoadingViewController(withHud: false)
    
    @IBOutlet weak var captureButton: RecordButton!
    @IBOutlet weak var flashButton: PopButton!
    @IBOutlet weak var flipCameraButton: PopButton!
    
    var chatWithFriend: ChatWithFriend? {
        didSet {
            chat = chatWithFriend?.chat
            friend = chatWithFriend?.friend
        }
    }
    private var chat: Chat?
    private var friend: User?

    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    private var longPressGesture: UILongPressGestureRecognizer!
    private lazy var dismissPanGesture = UIPanGestureRecognizer(target: self, action: #selector(dismissPanGestureRecognizerHandler(_:)))
    
    private lazy var cancelButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-multiply-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()
    
    private let sendToLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var sendPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test", for: .normal)
        button.addTarget(self, action: #selector(sendPhoto), for: .touchUpInside)
        return button
    }()
    
    
    @objc private func sendPhoto() {
        let photo = UIImage(named: "IMG_1536")
        let dbs = DatabaseService()
        
        let data = photo?.jpegData(compressionQuality: Compression.photoQuality)
        let thumbnailData = photo?.jpegData(compressionQuality: Compression.thumbnailQuality)
        
        let message = Message(senderUid: UserController.shared.currentUser!.uid, caption: "Test", status: .sending, messageType: .photo)
        dismiss(animated: true) {
            
            dbs.send(message, from: UserController.shared.currentUser!, to: self.friend!, chat: self.chat!, mediaData: data, thumbnailData: thumbnailData) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("Sent photo for testing")
            }
        }
    }
  
    override func viewDidLoad() {
        videoGravity = .resizeAspectFill
        super.viewDidLoad()
        
        
        shouldPrompToAppSettings = true
        maximumVideoDuration = 10.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = true
        swipeToZoom = false
        swipeToZoomInverted = true
        cameraDelegate = self
        videoQuality = .high
        
        
        VideoResolution.size = CGSize(width: 1080, height: 1920)
        
        updateView()
        
        captureButton.buttonEnabled = false
        
        sendToLabel.addShadow()
        cancelButton.addShadow()
        captureButton.addShadow()
        flashButton.addShadow()
        flipCameraButton.addShadow()

        view.addGestureRecognizer(dismissPanGesture)
        dismissPanGesture.maximumNumberOfTouches = 1
        
        view.layer.cornerRadius = 10
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        
        setStatusBar(hidden: true)
        showButtons()
        dismissPanGesture.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureButton.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
                
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        showButtons()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func cameraSwitchTapped(_ sender: UIButton) {
        
        switchCamera()
    }
    
    @IBAction func toggleFlashTapped(_ sender: UIButton) {
        flashEnabled = !flashEnabled
        toggleFlashAnimation()
    }
    
    @objc func cancelButtonTapped(_ sender: PopButton) {
        sender.pop {
            self.dismiss(animated: true, completion: nil)
            self.setStatusBar(hidden: false)
        }
    }
    
    @objc private func dismissPanGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                
                
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                    self.setStatusBar(hidden: false)
                }
            } else {
                DispatchQueue.main.async {
                    self.setStatusBar(hidden: true)
                    
                }
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                    
                })
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == panGesture && otherGestureRecognizer == dismissPanGesture) {
            return true
        }

        return false
    }
}

// MARK: - UI
private extension CameraViewController {
    func updateView() {
        view.addSubviews([cancelButton, sendToLabel])
        
        
        
        let topAnchor: CGFloat = 0
        
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: topAnchor, left: 16, bottom: 0, right: 0), size: .init(width: buttonSize, height: buttonSize))
//        cancelButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor).isActive = true
        
        //captureButton.anchorCenterXToSuperview()
//        captureButton.anchor(top: nil, leading: nil, bottom: view.bottomAnchor, trailing: nil)
        
        
        flashButton.anchor(top: nil, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16), size: .init(width: buttonSize, height: buttonSize))
        flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor).isActive = true
        
        flipCameraButton.anchor(top: nil, leading: nil, bottom: flashButton.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 16, right: 16), size: .init(width: buttonSize, height: buttonSize))
        
        
        #if targetEnvironment(simulator)
            view.addSubview(sendPhotoButton)
            sendPhotoButton.anchor(top: view.topAnchor, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 16, left: 0, bottom: 0, right: 16))
        #endif
        
        
        sendToLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: topAnchor, left: 0, bottom: 0, right: 0))
        sendToLabel.anchorCenterXToSuperview()
        
        if let friend = friend {
            let attributedText = NSMutableAttributedString(string: "Send to\n", attributes: [.font: UIFont.systemFont(ofSize: 16)])
            attributedText.append(NSAttributedString(string: "\(friend.displayName)", attributes: [.font: UIFont.boldSystemFont(ofSize: 16)]))
            sendToLabel.attributedText = attributedText
        }
        
        flipCameraButton.tintColor = .white
        flashButton.tintColor = .white
        cancelButton.tintColor = .white
    }
    
    func setStatusBar(hidden: Bool, duration: TimeInterval = 0.25) {
        
        let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        UIView.animate(withDuration: duration) {
            statusBarWindow?.alpha = hidden ? 0.0 : 1.0
        }
    }
    
}

// UI Animations
extension CameraViewController {
    
    fileprivate func hideButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 0.0
            self.flipCameraButton.alpha = 0.0
            self.cancelButton.alpha = 0.0
        }
    }
    
    fileprivate func showButtons() {
        
        flipCameraButton.setImage(#imageLiteral(resourceName: "icons8-switch_camera"), for: .normal)
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 1.0
            self.flipCameraButton.alpha = 1.0
            self.cancelButton.alpha = 1.0
        }
    }
    
    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
    fileprivate func toggleFlashAnimation() {
        if flashEnabled == true {
            flashButton.setImage(#imageLiteral(resourceName: "icons8-flash_on"), for: UIControl.State())
        } else {
            flashButton.setImage(#imageLiteral(resourceName: "icons8-flash_off"), for: UIControl.State())
        }
     }
}

// MARK: - SwiftyCamViewControllerDelegate
extension CameraViewController: SwiftyCamViewControllerDelegate {
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
        captureButton.buttonEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
        captureButton.buttonEnabled = false
    }
    
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        let newVC = PreviewMediaViewController(image: photo)
        newVC.friend = friend
        newVC.chat = chat
        //self.present(newVC, animated: false, completion: nil)
        navigationController?.pushViewController(newVC, animated: false)
        dismissPanGesture.isEnabled = false
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        swipeToZoom = true
        captureButton.growButton(maximumVideoDuration)
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        swipeToZoom = false
        captureButton.shrinkButton()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        let newVC = PreviewMediaViewController(videoURL: url)
        newVC.friend = friend
        newVC.chat = chat
        
//        add(newVC)
        showButtons()
        dismissPanGesture.isEnabled = false
//        self.present(newVC, animated: false, completion: nil)
        navigationController?.pushViewController(newVC, animated: false)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        presentAlert(alertController)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        print("Zoom level did change. Level: \(zoom)")
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        print("Camera did change to \(camera.rawValue)")
        flipCameraButton.pop()
        if camera == .front {
            flipCameraButton.setImage(#imageLiteral(resourceName: "icons8-camera_icon_with_face"), for: .normal)
        } else {
            flipCameraButton.setImage(#imageLiteral(resourceName: "icons8-switch_camera"), for: .normal)
        }
        
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
}
