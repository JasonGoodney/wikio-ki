import UIKit
import AVFoundation
import AVKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import JGProgressHUD

let buttonSize: CGFloat = 36

class PreviewMediaViewController: UIViewController {
    
    var friend: User? {
        didSet {
            configure()
        }
    }
    
    private var previousCaptionConstraints: [NSLayoutConstraint] = []
    private var previousCaptionFrame = CGRect()
    private var captionIsInSuperview = false
    private var captionCanBeDragged = false
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.isHidden = true
        return view
    }()
    
    private var backgroundImageView = UIImageView()
    
    lazy var cancelButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "back_button").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    lazy var addCaptionButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "add_text").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(addCaptionButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var resignCaptionEditButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "icons8-undo").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(resignCaptionEditButtonTapped(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var sendView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.addSubviews(sendToLabel, sendButton)
        return view
    }()
    
    private let sendToLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    lazy var sendButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "paper_plane").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(sendButtonTapped(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.layer.cornerRadius = 28
        return button
    }()
    
    lazy var captionTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        textField.delegate = self
        textField.setLeftPaddingPoints(8)
        textField.setRightPaddingPoints(8)
        textField.textColor = .white
        textField.addGestureRecognizer(captionDragGesture)
        textField.isHidden = true
        return textField
    }()
    
    private var videoURL: URL?
    private var image: UIImage?
    var player: AVPlayer?
    var playerController : AVPlayerViewController?
    
    private lazy var addTextTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped(_:)))
        return gesture
    }()
    
    private lazy var captionDragGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(captionDragGestureDragged(_:)))
        return gesture
    }()
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray
        
        if let videoURL = videoURL {
            configure(videoURL)
        } else if let image = image {
            configure(image)
        }
        
        updateView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }
    
    func configure() {
        if let friend = friend {
            sendToLabel.text = friend.username
        }
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
    
    func configure(_ image: UIImage) {
        backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFit
        backgroundImageView.image = image
        view.addSubview(backgroundImageView)
    }
    
    // MARK: - Actions
    @objc func cancel() {
        dismiss(animated: false, completion: nil)
    }
    
    func imageFromView(_ myView: UIView) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(myView.bounds.size, false, UIScreen.main.scale)
        self.view.drawHierarchy(in: myView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    @objc func sendButtonTapped(_ sender: UIButton) {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = view.bounds
        
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        guard let currentUser = UserController.shared.currentUser,
            let friend = friend else { return }
        var messageCaption: String? = nil
        var messageImageData: Data? = nil
        var messageVideoURL: String? = nil
        var messageType: MessageType = .photo
        
        if captionTextField.text != "", let caption = captionTextField.text, let image = image {
            messageCaption = caption
//            message.image = UIImage.createImageWithLabelOverlay(textField: captionTextField, imageSize: backgroundImageView.frame.size, image: image)
            let processor = ImageProcessor()
            let image = processor.addOverlay(captionTextField, to: image, size: view.frame.size)
            messageImageData = image.jpegData(compressionQuality: Compression.quality)
        } else if let image = image {
            messageImageData = image.jpegData(compressionQuality: Compression.quality)
        } else if let videoURL = videoURL {
            let processor = VideoProcessor()
            let captionProcessor = CaptionProcessor()
            let captionImage = captionProcessor.imageFromView(captionTextField)
            let captionAsImage = captionTextField.asImage()
           // message.videoURL = processor.addOverlay(captionTextField, to: videoURL, size: view.frame.size)
        
            let config = MergeConfiguration.customPlacement(captionTextField.frame)
            let merge = Merge(config: config)
            let asset = AVAsset(url: videoURL)
            
            merge.overlayVideo(video: asset, overlayImage: captionTextField.asImage(), completion: { (url) in
                guard let url = url else { return }
                messageVideoURL = url.absoluteString
            }) { (progress) in
                print(progress)
            }
            messageType = .video
        }
        
        let message = Message(senderUid: currentUser.uid, user: currentUser, caption: messageCaption, messageType: messageType)
        let chatUid = "\(min(currentUser.uid, friend.uid))_\(max(currentUser.uid, friend.uid))"
        print("chatUID: \(chatUid)")
        let chat = Chat(uid: chatUid, memberUids: [currentUser.uid, friend.uid], lastMessageSent: message.uid, lastSenderUid: currentUser.uid, isNewFriendship: false)
        
        if let data = messageImageData {
            let hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Sending"
            hud.vibrancyEnabled = true
            hud.show(in: view)
            StorageService.saveMediaToStorage(data: data, for: message) { (messageWithMedia, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let message = messageWithMedia else { return }
                let databaseService = DatabaseService()
                databaseService.save(message, in: chat, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("Sent message from \(currentUser.username) to \(self.friend!.username)")
                    hud.dismiss()
                    MessageController.shared.messages.append(message)
                    self.dismiss(animated: false, completion: nil)
                    self.presentingViewController?.dismiss(animated: false) {
                        DispatchQueue.main.async {
                            
                            message.status = .delivered
                        }
                    }
                })
            }
        }
    }
    
    private func saveImageToFirebase(data: Data, for message: Message, completion: @escaping ErrorCompletion) {
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/images/\(filename)")
        
        ref.putData(data, metadata: nil) { (_, error) in
            if let error = error {
                completion(error)
                return
            }
            
            ref.downloadURL(completion: { (url, error) in
                if let error = error {
                    completion(error)
                    return
                }
                let imageUrl = url?.absoluteString ?? ""
                
                message.mediaURL = imageUrl
                MessageController.shared.messages.append(message)
                self.dismiss(animated: false, completion: nil)
                self.presentingViewController?.dismiss(animated: false) {
                    DispatchQueue.main.async {
                        
                        message.status = .delivered
                    }
                }
                self.saveInfoToFirestore(message: message, completion: completion)
            })
        }
    }
    
    private func saveInfoToFirestore(message: Message, completion: @escaping ErrorCompletion) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let messageData = message.dictionary()
        Firestore.firestore().collection("messages").document(uid).setData(messageData) { (error) in
            if let error = error {
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    @objc func addCaptionButton(_ sender: UIButton) {
        handleCaptionResponder()
    }
    
    @objc func captionDragGestureDragged(_ recognizer: UIPanGestureRecognizer) {
        if captionCanBeDragged {
            let translation = recognizer.translation(in: self.view)
            let height = UIScreen.main.bounds.height
            if let view = recognizer.view, view.frame.minY > 0 , view.frame.maxY < height {
                view.center = CGPoint(x:view.center.x,
                                      y:view.center.y + translation.y)
            }
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    @objc func screenTapped(_ sender: UITapGestureRecognizer) {
        handleCaptionResponder()
    }
    
    @objc func resignCaptionEditButtonTapped(_ sender: UIButton) {
        handleCaptionResponder()
    }
    
    func handleCaptionResponder() {
        addCaptionButton.pop()
        // Caption Active
        if captionIsInSuperview {
            if captionTextField.text != "" && captionCanBeDragged {
                captionTextField.becomeFirstResponder()
                dimView.isHidden = false
                cancelButton.isHidden = true
                resignCaptionEditButton.isHidden = false
            } else if captionTextField.text == "" {
                captionTextField.isHidden = true
                dimView.isHidden = true
                cancelButton.isHidden = false
                resignCaptionEditButton.isHidden = true
                captionIsInSuperview = false
                captionTextField.resignFirstResponder()
            } else {
                captionTextField.frame = previousCaptionFrame
                captionTextField.setNeedsDisplay()
                captionTextField.resignFirstResponder()
                UIView.animate(withDuration: 0.2) {
                    self.captionTextField.textAlignment = .center
                }
                captionTextField.isHidden = false
                dimView.isHidden = true
                cancelButton.isHidden = false
                resignCaptionEditButton.isHidden = true
            }
        }
        // Caption Not Active
        else {
            captionTextField.becomeFirstResponder()
            captionTextField.isHidden = false
            dimView.isHidden = false
            cancelButton.isHidden = true
            resignCaptionEditButton.isHidden = false
            captionIsInSuperview = true
        }
    }
    
    private func sendMessage(_ message: Message) {
        
    }
}

// MARK: - UI
private extension PreviewMediaViewController {
    func updateView() {
        view.addSubviews(dimView, captionTextField, cancelButton, resignCaptionEditButton, addCaptionButton, sendView)
        view.addGestureRecognizer(addTextTapGesture)
        setupConstraints()
        
        UITextField.appearance().tintColor = .white
    }
    
    func setupConstraints() {

        cancelButton.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 24, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: buttonSize, heightConstant: buttonSize)
        
        resignCaptionEditButton.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 24, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: buttonSize, heightConstant: buttonSize)
        
        dimView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        captionTextField.anchor(nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 36)
        
        addCaptionButton.anchor(view.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, topConstant: 24, leftConstant: 0, bottomConstant: 0, rightConstant: 16, widthConstant: buttonSize, heightConstant: buttonSize)
        
        sendView.anchor(nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: view.frame.width, heightConstant: 64)
        
        sendButton.anchorCenterYToSuperview()
        sendButton.anchor(top: nil, leading: nil, bottom: nil, trailing: sendView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 20))
        
        sendToLabel.anchorCenterYToSuperview()
        sendToLabel.anchor(top: nil, leading: nil, bottom: nil, trailing: sendButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16))
    }
}

// MARK: - UITextFieldDelegate
extension PreviewMediaViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {

        textField.textAlignment = .left
        captionCanBeDragged = false
        captionTextField.anchorCenterXToSuperview()
        captionTextField.anchorCenterYToSuperview()
        captionTextField.setNeedsUpdateConstraints()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        captionCanBeDragged = true
        if textField.text?.last == " " {
            textField.text?.removeLast()
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

extension UIImage {
    
    class func createImageWithLabelOverlay(textField: UITextField,imageSize: CGSize, image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 2.0)
        let currentView = UIView.init(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let currentImage = UIImageView.init(image: image)
        currentImage.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        currentView.addSubview(currentImage)
        currentView.addSubview(textField)
        currentView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
}
