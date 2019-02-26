import UIKit
import AVFoundation
import AVKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import JGProgressHUD
import Photos
import ColorSlider

let buttonSize: CGFloat = 44

//<div>Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/"             title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/"             title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>

class PreviewMediaViewController: UIViewController {
    
    var chat: Chat?
    var friend: User? {
        didSet {
            configure()
        }
    }
    
    // Caption charater Limit
    private var characterLimit = 140
    private var captionIsInSuperview = false
    private var captionCanBeDragged = false
    private var previousCaptionPoint: CGPoint!
    
    // Drawing
    
    private lazy var sketchView: SketchView = {
        let view = SketchView(frame: self.view.frame)
        view.isHidden = true
        view.sketchViewDelegate = self
        view.lineColor = colorSlider.color
        view.lineWidth = 7
        
        return view
    }()
    
    private lazy var colorSlider: ColorSlider = {
        let previewView = DefaultPreviewView()
        previewView.side = .left
        previewView.scaleAmounts = [.active: 3.0]
        previewView.offsetAmount = 75
        
        let slider = ColorSlider(orientation: .vertical, previewView: previewView)
        slider.addTarget(self, action: #selector(changedColor), for: .valueChanged)
        slider.isHidden = true
        slider.addShadow()
        
        return slider
    }()
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom, .top]
    }
    
    private lazy var editContainerView: UIView = {
        let view = UIView()
        view.addSubviews([sketchView, captionTextView])
        return view
    }()
    
    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.isHidden = true
        return view
    }()
    
    private let saveToCameraRollImage = #imageLiteral(resourceName: "icons8-downloading_updates").withRenderingMode(.alwaysTemplate)
    private let cancelImage = #imageLiteral(resourceName: "icons8-back-filled-96").withRenderingMode(.alwaysTemplate)
    private let addCaptionImage = #imageLiteral(resourceName: "icons8-type_filled").withRenderingMode(.alwaysTemplate)
    private let resignCaptionImage = ""
    private let soundOnImage = ""
    private let soundOffImage = ""
    private let sendImage = ""
    private let drawImage = #imageLiteral(resourceName: "icons8-pencil").withRenderingMode(.alwaysTemplate)
    private let undoImage = #imageLiteral(resourceName: "icons8-undo").withRenderingMode(.alwaysTemplate)
    private let confirmImage = #imageLiteral(resourceName: "icons8-ok").withRenderingMode(.alwaysTemplate)
    private let eraserImage = #imageLiteral(resourceName: "icons8-eraser").withRenderingMode(.alwaysTemplate)
    
    private var backgroundImageView = UIImageView()
    
    private lazy var cancelButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "icons8-back-filled-96").withRenderingMode(.alwaysTemplate), for: .normal) // Too Small
        button.tintColor = .white
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    private lazy var addCaptionButton: PopButton = {
        let button = PopButton()
        button.setImage(addCaptionImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(addCaptionButton(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var resignCaptionEditButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "icons8-undo").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(resignCaptionEditButtonTapped(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var toggleVideoSoundButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "icons8-room_sound_filled").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(toggleVideoSound), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var toggleDrawingButton: PopButton = {
        let button = PopButton()
        button.setImage(drawImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(toggleDrawingButtonTapped), for: .touchUpInside)
        button.addShadow()
        return button
    }()
    
    private lazy var undoButton: PopButton = {
        let button = PopButton()
        button.setImage(undoImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        button.addShadow()
        button.isHidden = true
        return button
    }()
    
    private lazy var eraserButton: PopButton = {
        let button = PopButton()
        button.setImage(eraserImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(eraserButtonTapped), for: .touchUpInside)
        button.addShadow()
        button.isHidden = true

        return button
    }()
    
    private lazy var penButton: PopButton = {
        let button = PopButton()
        button.setImage(drawImage, for: .normal)
        button.tintColor = colorSlider.color
        button.addTarget(self, action: #selector(penButtonTapped), for: .touchUpInside)
        button.addShadow()
        button.isHidden = true

        return button
    }()
    
    private lazy var sendToView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.addSubviews(sendToLabel)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addMoreFriends)))
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let sendToLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 0
        label.addShadow()
        return label
    }()
    
    private lazy var sendButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "iconfinder_web_9_3924904").withRenderingMode(.alwaysTemplate), for: .normal)
        button.backgroundColor = .clear
        button.tintColor = .white
        button.addTarget(self, action: #selector(sendButtonTapped(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.layer.cornerRadius = 28
        button.imageEdgeInsets = .init(top: 8, left: 9.5, bottom: 8, right: 6.5)
        button.backgroundColor = Theme.buttonBlue
        button.addShadow()
        return button
    }()
    
    private lazy var saveToCameraRollButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(saveToCameraRollImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(saveToCameraRollButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var captionTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        textView.delegate = self
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.addGestureRecognizer(captionDragGesture)
        textView.isHidden = true
        textView.isScrollEnabled = false
        return textView
    }()
    
    private lazy var screenTapButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(screenTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    private var videoURL: URL?
    private var image: UIImage?
    var player: AVPlayer?
    var playerController : AVPlayerViewController?
    
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
        self.view.backgroundColor = UIColor.black
        
        if let videoURL = videoURL {
            configure(videoURL)
        } else if let image = image {
            configure(image)
        }
        
        updateView()
        
        cancelButton.addShadow()
        addCaptionButton.addShadow()
        resignCaptionEditButton.addShadow()
        toggleVideoSoundButton.addShadow()
        saveToCameraRollButton.addShadow()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if videoURL != nil {
            playFromBeginning()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if videoURL != nil {
            player?.pause()
        }
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
            if image != nil {
            } else if videoURL != nil {
                self.remove()
            }
    }
    
    func imageFromView(_ myView: UIView) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(myView.bounds.size, false, UIScreen.main.scale)
        self.view.drawHierarchy(in: myView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    let loadingViewController = LoadingViewController(hudText: "Sending\nDo not close 🙏")
    
    func generateThumbnail(for asset: AVAsset) -> UIImage? {
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 0, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
        
    }
    
    func generateOutput() {
        
    }
    
    @objc func sendButtonTapped(_ sender: UIButton) {
        if chat == nil {
            var sendToVC: SendToViewController
            if let image = image {
                let imageEdits = editContainerView.screenshot()
                let editedImage = image.imageMontage(img: imageEdits, bgColor: nil, size: view.frame.size)
                sendToVC = SendToViewController(image: editedImage)
                present(sendToVC, animated: false, completion: nil)
            } else if let videoURL = videoURL {
                sendToVC = SendToViewController(videoURL: videoURL)
                present(sendToVC, animated: false, completion: nil)
            }
            return
        }
        
        let hud = JGProgressHUD(style: .dark)
        
        guard let currentUser = UserController.shared.currentUser,
            let friend = friend else { return }
        
        //chat?.status = .sending
        chat?.isSending = true
        
        var messageCaption: String? = nil
        var mediaData: Data? = nil
        var messageThumbnailData: Data? = nil
        
        if let sketch = image, sketchView.hasDrawing {
            let processor = ImageProcessor()
            image = processor.addOverlay(sketchView, to: sketch, size: view.frame.size)
        }
        
        if captionTextView.text != "", let caption = captionTextView.text, let image = image {
            messageCaption = caption
            let processor = ImageProcessor()
            
            let image = processor.addOverlay(captionTextView, to: image, size: view.frame.size)
            mediaData = image.jpegData(compressionQuality: Compression.photoQuality)
            messageThumbnailData = image.jpegData(compressionQuality: Compression.thumbnailQuality)

            self.dismiss(animated: false)
            self.presentingViewController?.dismiss(animated: false) {
                let dbs = DatabaseService()
                let message = Message(senderUid: currentUser.uid, caption: caption, status: .sending, messageType: .photo)
                
                dbs.send(message, from: currentUser, to: friend, chat: self.chat!, mediaData: mediaData, thumbnailData: messageThumbnailData, completion: { (error) in
                    if let error = error {
                        print(error)
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.textLabel.text = error.localizedDescription
                        hud.show(in: self.view)
                    }
                    print("Sent from DataBaseService")
                })
            }
            
        } else if let image = image {
            mediaData = image.jpegData(compressionQuality: Compression.photoQuality)
            messageThumbnailData = image.jpegData(compressionQuality: Compression.thumbnailQuality)

            
            self.dismiss(animated: false)
            self.presentingViewController?.dismiss(animated: false) {
                let dbs = DatabaseService()
                let message = Message(senderUid: currentUser.uid, status: .sending, messageType: .photo)
                
                dbs.send(message, from: currentUser, to: friend, chat: self.chat!, mediaData: mediaData, thumbnailData: messageThumbnailData, completion: { (error) in
                    if let error = error {
                        print(error)
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.textLabel.text = error.localizedDescription
                        hud.show(in: self.view)
                    }
                    print("Sent from DataBaseService")
                })
            }
            
        } else if let videoURL = videoURL {
            let process = Process()
            let caption: UITextView? = captionTextView.text != "" ? captionTextView : nil
            let captionText = caption?.text
            DispatchQueue.main.async {
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.dismiss(animated: false, completion: nil)
                self.presentingViewController?.dismiss(animated: false, completion: {
            
            process.video(url: videoURL, inView: self.view, caption: caption) { (data, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let data = data else { return }
                
                        
                        let dbs = DatabaseService()
                        let message = Message(senderUid: currentUser.uid, caption: captionText, status: .sending, messageType: .video)
                        
                        dbs.send(message, from: currentUser, to: friend, chat: self.chat!, mediaData: data, thumbnailData: data, completion: { (error) in
                            if let error = error {
                                print(error)
                                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                hud.textLabel.text = error.localizedDescription
                                hud.show(in: self.view)
                            }
                            print("Sent from DataBaseService")
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        })
                        // self.presentingViewController?.dismiss(animated: false)
                    }
                })
            }
        }
    }
    
    private func playFromBeginning() {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }

    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        playFromBeginning()
    }
    
    @objc private func addCaptionButton(_ sender: UIButton) {
        handleCaptionResponder()
    }
    
    @objc private func captionDragGestureDragged(_ recognizer: UIPanGestureRecognizer) {
        if captionCanBeDragged {
            let view = editContainerView
            let translation = recognizer.translation(in: view)
            switch recognizer.state {
            case .began, .changed:
                if let view = recognizer.view {
                    view.center = CGPoint(x:view.center.x,
                                          y:view.center.y + translation.y)
                }
                recognizer.setTranslation(CGPoint.zero, in: view)
                break
            default:
                break
            }
        }
    }
    
    @objc private func screenTapped(_ sender: UITapGestureRecognizer) {
        addCaptionButton.pop()
        handleCaptionResponder()
    }
    
    @objc private func resignCaptionEditButtonTapped(_ sender: UIButton) {
        addCaptionButton.pop()
        handleCaptionResponder()
    }
    
    @objc private func toggleVideoSound() {
        player?.isMuted = !player!.isMuted
        
        let image = player!.isMuted ? #imageLiteral(resourceName: "icons8-mute_filled") : #imageLiteral(resourceName: "icons8-room_sound_filled")
        toggleVideoSoundButton.setImage(image, for: .normal)
    }
    
    func handleCaptionResponder() {
        
        // Caption Active
        if captionIsInSuperview {
            
            if captionTextView.text != "" && captionCanBeDragged {
                captionTextView.becomeFirstResponder()
                dimView.isHidden = false
                cancelButton.isHidden = true
                
            } else if captionTextView.text == "" {
                captionTextView.isHidden = true
                dimView.isHidden = true
                cancelButton.isHidden = false
                
                captionIsInSuperview = false
                captionTextView.resignFirstResponder()
            } else {
                captionTextView.setNeedsDisplay()
                captionTextView.resignFirstResponder()
                UIView.animate(withDuration: 0.2) {
                    self.captionTextView.textAlignment = .center
                }
                captionTextView.isHidden = false
                dimView.isHidden = true
                cancelButton.isHidden = false
                
            }
        }
        // Caption Not Active
        else {
            captionTextView.becomeFirstResponder()
            captionTextView.isHidden = false
            dimView.isHidden = false
            cancelButton.isHidden = true
            //resignCaptionEditButton.isHidden = false
            captionIsInSuperview = true
        }
        
        if captionTextView.isFirstResponder {
            toggleDrawingButton.isHidden = true
            addCaptionButton.setImage(confirmImage, for: .normal)
        } else {
            toggleDrawingButton.isHidden = false
            addCaptionButton.setImage(addCaptionImage, for: .normal)
        }
    }
    
    @objc private func addMoreFriends() {
//        let addMoreFriendsViewController = SendToViewController()
//        let navVC = UINavigationController(rootViewController: addMoreFriendsViewController)
//        present(navVC, animated: true, completion: nil)
    }
    
    @objc func undoButtonTapped() {
        
        if !sketchView.hasDrawing {
            undoButton.isHidden = true
            return
        }
        sketchView.undo()
    }

    @objc func eraserButtonTapped() {
        sketchView.drawTool = .eraser
    }
    
    @objc func penButtonTapped() {
        sketchView.drawTool = .pen
    }
    
    private var canBeginDrawing = false
    @objc private func toggleDrawingButtonTapped() {

        canBeginDrawing = !canBeginDrawing

        sketchView.drawTool = .pen
        if sketchView.hasDrawing {
            undoButton.isHidden = false

            colorSlider.isHidden = !colorSlider.isHidden
        } else {
            sketchView.isHidden = !sketchView.isHidden
            colorSlider.isHidden = !colorSlider.isHidden
            undoButton.isHidden = true

        }
        
        if canBeginDrawing {
            beginDrawing()
            
        } else {
            endDrawing()
        }
    }
    
    func beginDrawing() {
        captionCanBeDragged = false
        captionTextView.isUserInteractionEnabled = false
        addCaptionButton.isHidden = true
        saveToCameraRollButton.isHidden = true
        cancelButton.isHidden = true
        eraserButton.isHidden = false
        penButton.isHidden = false
        sketchView.isUserInteractionEnabled = true
        toggleDrawingButton.setImage(confirmImage, for: .normal)
        captionTextView.isHidden = captionTextView.text == ""
        screenTapButton.isHidden = true
        sendButton.isHidden = true
        if videoURL != nil {
            toggleVideoSoundButton.isHidden = true
        }
    }
    
    func endDrawing() {
        captionCanBeDragged = true
        captionTextView.isUserInteractionEnabled = true
        addCaptionButton.isHidden = false
        saveToCameraRollButton.isHidden = false
        cancelButton.isHidden = false
        undoButton.isHidden = true
        penButton.isHidden = true
        eraserButton.isHidden = true
        sketchView.isUserInteractionEnabled = false
        toggleDrawingButton.setImage(drawImage, for: .normal)
        screenTapButton.isHidden = false
        sendButton.isHidden = false
        if videoURL != nil {
            toggleVideoSoundButton.isHidden = false
        }
    }
    
    @objc private func changedColor(_ slider: ColorSlider) {
        sketchView.lineColor = slider.color
        penButton.tintColor = slider.color
    }
    
    @objc private func saveToCameraRollButtonTapped() {
        print("🤶\(#function)")
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            DispatchQueue.main.async {
                if let image = self.image {
                    self.saveToCameraRoll(image: image)
                } else if let videoURL = self.videoURL {
                    self.saveToCameraRoll(videoURL: videoURL)
                }
            }
            
        } else {
            PHPhotoLibrary.requestAuthorization { (status) in
                
                if status == .authorized {
                    DispatchQueue.main.async {
                        if let image = self.image {
                            self.saveToCameraRoll(image: image)
                        } else if let videoURL = self.videoURL {
                            self.saveToCameraRoll(videoURL: videoURL)
                        }
                    }
                }
            
            }
        }
        
    }
    
    private func saveToCameraRoll(image: UIImage? = nil, videoURL: URL? = nil) {
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Saving"
        hud.show(in: self.view)

        if var image = image {
            let processor = ImageProcessor()
//            if sketchView.hasDrawing {
//                image = image.addOverlay(sketchView, size: view.frame.size)
//            }
//            if captionTextView.text != "" {
//                image = image.addOverlay(captionTextView, size: view.frame.size)
//            }
            
            let imageEdits = editContainerView.screenshot()
            let edittedImage = image.imageMontage(img: imageEdits, bgColor: nil, size: view.frame.size)
            hud.dismiss()
            //let image = processor.addOverlay(captionTextView, to: image, size: view.frame.size)
//
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAsset(from: image)
//            }, completionHandler: { success, error in
//                if success {
//                    // Saved successfully!
//                   print("Saved to photo library")
//                }
//                else if let error = error {
//                    // Save photo failed with error
//                    DispatchQueue.main.async {
//                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
//                        hud.textLabel.text = error.localizedDescription
//                        hud.dismiss(afterDelay: 1)
//                    }
//                }
//                else {
//                    // Save photo failed with no error
//                }
//            })
        } else if let videoURL = videoURL {
            
            if captionTextView.text != "" {
                let process = Process()
                
                process.addOverlay(url: videoURL, inView: self.view, caption: captionTextView) { (url) in
                    guard let url = url else { return }
//                    PHPhotoLibrary.shared().performChanges({
//                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
//                    }, completionHandler: { success, error in
//                        if success {
//                            // Saved successfully!
//                            print("Saved to photo library")
//                        }
//                        else if let error = error {
//                            // Save photo failed with error
//                            DispatchQueue.main.async {
//                                hud.indicatorView = JGProgressHUDErrorIndicatorView()
//                                hud.textLabel.text = error.localizedDescription
//                                hud.dismiss(afterDelay: 1)
//                            }
//                        }
//                        else {
//                            // Save photo failed with no error
//                        }
//                    })
                }
            } else {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }, completionHandler: { success, error in
                    if success {
                        // Saved successfully!
                        print("Saved to photo library")
                    }
                    else if let error = error {
                        // Save photo failed with error
                        DispatchQueue.main.async {
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.textLabel.text = error.localizedDescription
                            hud.dismiss(afterDelay: 1)
                        }
                    }
                    else {
                        // Save photo failed with no error
                    }
                })
            }
        }
    }
}

// MARK: - UI
private extension PreviewMediaViewController {
    func updateView() {
        
        let editButtonsStackView = UIStackView(arrangedSubviews: [toggleVideoSoundButton, addCaptionButton, toggleDrawingButton])
        editButtonsStackView.spacing = 16

        view.addSubviews([dimView, editContainerView, colorSlider, cancelButton, editButtonsStackView, resignCaptionEditButton, undoButton, penButton, eraserButton, sendButton, sendToLabel, saveToCameraRollButton])
        
        editContainerView.isUserInteractionEnabled = true
        
        if player != nil {
            toggleVideoSoundButton.isHidden = false
        }
        
        sketchView.sketchViewDelegate = self
        
        let left: CGFloat = 16
        let top: CGFloat = 16
        let right: CGFloat = 16
        let bottom: CGFloat = 16
        
        editContainerView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)

        dimView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        captionTextView.frame = CGRect(x: 0, y: view.frame.midY, width: view.frame.width, height: 36)
        
        editButtonsStackView.anchor(top: view.topAnchor, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: top, left: 0, bottom: 0, right: right))
        editButtonsStackView.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true

        cancelButton.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil,
                            topConstant: top, leftConstant: left, bottomConstant: 0, rightConstant: 0, widthConstant: buttonSize, heightConstant: buttonSize)

        resignCaptionEditButton.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil,
                                       topConstant: top, leftConstant: left, bottomConstant: 0, rightConstant: 0, widthConstant: buttonSize, heightConstant: buttonSize)

        sendButton.anchor(top: nil, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 8, right: 8))
        
        
        sendToLabel.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor).isActive = true
        sendToLabel.anchor(top: nil, leading: nil, bottom: nil, trailing: sendButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: right))
        
        saveToCameraRollButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: left, bottom: bottom, right: 0))
        
        sketchView.anchor(top: editContainerView.topAnchor, leading: editContainerView.leadingAnchor, bottom: editContainerView.bottomAnchor, trailing: editContainerView.trailingAnchor)

        colorSlider.anchor(top: editButtonsStackView.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: top, left: 0, bottom: 0, right: 0), size: .init(width: 15, height: 150))
        
        colorSlider.centerXAnchor.constraint(equalTo: toggleDrawingButton.centerXAnchor).isActive = true
        
        eraserButton.centerXAnchor.constraint(equalTo: toggleDrawingButton.centerXAnchor).isActive = true
        eraserButton.anchor(top: colorSlider.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: top, left: 0, bottom: 0, right: 0))
        
        penButton.centerXAnchor.constraint(equalTo: toggleDrawingButton.centerXAnchor).isActive = true
        penButton.anchor(top: eraserButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: top, left: 0, bottom: 0, right: 0))
        undoButton.centerXAnchor.constraint(equalTo: toggleDrawingButton.centerXAnchor).isActive = true
        undoButton.anchor(top: penButton.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: top, left: 0, bottom: 0, right: 0))
        
        //screenTapButton.anchor(top: editButtonsStackView.bottomAnchor, leading: view.leadingAnchor, bottom: sendButton.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 20, left: 0, bottom: 20, right: 0))
    }
}

extension PreviewMediaViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if captionIsInSuperview {
            previousCaptionPoint = captionTextView.frame.origin
        } else {
            previousCaptionPoint = CGPoint(x: 0, y: view.frame.midY)
        }
        handleCaptionResponder()
        textView.textAlignment = .left
        captionCanBeDragged = false
        captionTextView.frame.origin = CGPoint(x: 0, y: view.frame.midY)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        captionTextView.frame.origin = previousCaptionPoint
        captionCanBeDragged = true
        if textView.text?.last == " " {
            textView.text?.removeLast()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let size = CGSize(width: view.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        textView.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        if text.count > 1 {
            #warning("Maybe warning saying pasted text is too long?")
            return text.count <= characterLimit
        }
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        return changedText.count <= characterLimit
    }
}

extension UITextInput {
    func textRange(for range: NSRange) -> UITextRange? {
        var result: UITextRange?
        
        if
            let start = position(from: beginningOfDocument, offset: range.location),
            let end = position(from: start, offset: range.length)
        {
            result = textRange(from: start, to: end)
            
        }
        
        return result
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// MARK: - Drawing Logic
extension PreviewMediaViewController: SketchViewDelegate {
    
    func drawView(_ view: SketchView, willBeginDrawUsingTool tool: AnyObject) {
        
        isDrawing(true)
        
        undoButton.isHidden = !view.hasDrawing
    }
    
    func drawView(_ view: SketchView, didEndDrawUsingTool tool: AnyObject) {

        isDrawing(false)
    }
    
    func isDrawing(_ isDrawing: Bool) {
        
        captionCanBeDragged = !isDrawing
        
        let alpha: CGFloat = isDrawing ? 0.0 : 1.0
        
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut], animations: {
            self.view.subviews.forEach({ (subview) in
                if subview == self.sketchView || subview == self.playerController?.view || subview == self.backgroundImageView || subview == self.editContainerView {
                    return
                }
                
                if subview == self.captionTextView {
                    subview.alpha = alpha
                }
                
                subview.alpha = alpha
            })
            
        }, completion: nil)
        
        
    }
}
