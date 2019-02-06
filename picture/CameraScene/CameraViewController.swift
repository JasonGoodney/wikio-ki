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

    private let blurViewController = LoadingViewController(withHud: false)
    
    @IBOutlet weak var captureButton: RecordButton!
    @IBOutlet weak var flashButton: PopButton!
    @IBOutlet weak var flipCameraButton: PopButton!
    
    var chat: Chat?
    var friend: User?

    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    private lazy var cancelButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-multiply-90"), for: .normal)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
        
        shouldPrompToAppSettings = true
        maximumVideoDuration = 10.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = true
        swipeToZoomInverted = true
        cameraDelegate = self
        
        VideoResolution.size = CGSize(width: 1080, height: 1920)
        
        captureButton.buttonEnabled = false
        
        sendToLabel.addShadow()
        cancelButton.addShadow()
        captureButton.addShadow()
        flashButton.addShadow()
        flipCameraButton.addShadow()
        
//        captureButton.closeWhenFinished = false
//        captureButton.addTarget(self, action: #selector(record), for: .touchDown)
//        captureButton.addTarget(self, action: #selector(stop), for: UIControl.Event.touchCancel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showButtons()
        
        if chat == nil || chat!.status != .sending {
            blurViewController.remove()
        }
        
        
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
        }
        
    }

}

// MARK: - UI
private extension CameraViewController {
    func updateView() {
        view.addSubviews([cancelButton, sendToLabel])
        
        cancelButton.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 16, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: 44, heightConstant: 44)
        
        sendToLabel.anchor(top: view.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 16, left: 0, bottom: 0, right: 0))
        sendToLabel.anchorCenterXToSuperview()
        
        if let friend = friend {
            let attributedText = NSMutableAttributedString(string: "Send to\n", attributes: [.font: UIFont.systemFont(ofSize: 16)])
            attributedText.append(NSAttributedString(string: "\(friend.username)", attributes: [.font: UIFont.boldSystemFont(ofSize: 16)]))
            sendToLabel.attributedText = attributedText
        }
        
        flipCameraButton.tintColor = .white
        flashButton.tintColor = .white
        cancelButton.tintColor = .white
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
        add(blurViewController)
        self.present(newVC, animated: false, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        captureButton.growButton(maximumVideoDuration)
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        captureButton.shrinkButton()
        
//        swiftyCam.buttonDidEndLongPress()
        
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        let newVC = PreviewMediaViewController(videoURL: url)
        newVC.friend = friend
        newVC.chat = chat
        //add(blurViewController)
        add(newVC)
        

        //self.present(newVC, animated: false, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        print("Zoom level did change. Level: \(zoom)")
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        print("Camera did change to \(camera.rawValue)")
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
