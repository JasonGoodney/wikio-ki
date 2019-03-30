//
//  SendToViewController.swift
//  picture
//
//  Created by Jason Goodney on 2/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import AVKit

class SendToViewController: UIViewController {
    
    // Pass back properties
    weak var delegate: PassBackDelegate?
    
    var passBackMediaData: Data? = nil {
        didSet {
            mediaData = passBackMediaData
            thumbnailData = passBackMediaData
        }
    }
    
    var passBackSelectedNames: Set<String>? = nil {
        didSet {
            selectedNames = passBackSelectedNames ?? []
        }
    }
    
    // Properties
    private var isProcessingMedia: Bool = true {
        didSet {
            DispatchQueue.main.async {
                if self.isProcessingMedia {
                    self.sendButton.setTitle("Processing...", for: .normal)
                    self.sendButton.setImage(nil, for: .normal)
                    self.sendButton.isEnabled = false
                    self.sendButton.backgroundColor = .lightGray
                } else {
                    self.sendButton.setTitle("Send  ", for: .normal)
                    self.sendButton.setImage(#imageLiteral(resourceName: "iconfinder_web_9_3924904").withRenderingMode(.alwaysTemplate), for: .normal)
                    self.sendButton.isEnabled = true
                    self.sendButton.backgroundColor = Theme.buttonBlue
                }
            }
        }
    }
    
    enum TableSection: Int {
        case preview = 0, bestFriends, recents, friends
    }
    
    private var selectionsCount: Int {
        return selectedNames.count
    }
    private var selectedNames: Set<String> = []
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(SendToCell.self, forCellReuseIdentifier: SendToCell.reuseIdentifier)
        view.register(SendToPreviewViewCell.self, forCellReuseIdentifier: SendToPreviewViewCell.reuseIdentifier)
        view.tableFooterView = UIView()
        view.separatorStyle = .none
        view.backgroundColor = Theme.ultraLightGray
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: (56+24+8), right: 0)
        return view
    }()
    
    private lazy var cancelButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "icons8-multiply-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = Theme.ultraDarkGray
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var sendButton: PopButton = {
        let button = PopButton(type: .custom)
//        button.setTitle("Send  ", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
//        button.setImage(#imageLiteral(resourceName: "iconfinder_web_9_3924904").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.alpha = 0
        button.backgroundColor = Theme.buttonBlue
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    private var image: UIImage? = nil
    
    private var videoURL: URL? = nil
    private var containerView: UIView? = nil
    
    private var mediaData: Data? = nil {
        didSet {
//            if selectionsCount > 0 {
//                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
//                    DispatchQueue.main.async {
//                        self.sendButton.alpha = 1
//                    }
//                }, completion: nil)
//            }
            if mediaData != nil {
                isProcessingMedia = false
            }
        }
    }
    private var thumbnailData: Data? = nil
    
    private var selectedCells: [SendToCell] = []
    
    private let previewSizeRatio: CGFloat = 0.25
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    init(videoURL: URL, containerView: UIView) {
        self.videoURL = videoURL
        self.containerView = containerView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        setStatusBar(hidden: false, duration: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setStatusBar(hidden: true, duration: 0)
    }
    
    func setStatusBar(hidden: Bool, duration: TimeInterval = 0.25) {
        
        let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        UIView.animate(withDuration: duration) {
            statusBarWindow?.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isProcessingMedia = true
        //if mediaData == nil {
            if let image = image {
                mediaData = image.jpegData(compressionQuality: Compression.photoQuality)
                thumbnailData = image.jpegData(compressionQuality: Compression.thumbnailQuality)
            } else if let videoURL = videoURL {
                let compressor = Compressor()
                let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".MP4")
                let process = Process()
                let image = containerView?.screenshot()
                if let image = image {
                    
                    process.addOverlay(url: videoURL, image: image) { (url) in
                        guard let url = url else { return }
                        compressor.compressFile(urlToCompress: url, outputURL: outputURL) { (url) in
                            do {
                                guard let mediaData = try? Data(contentsOf: url) else { return }
                                print("File size after compression: \(Double(mediaData.count / 1048576)) mb")
                                self.mediaData = mediaData
                                self.thumbnailData = mediaData
                            } catch let error {
                                print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
                            }
                        }
                    }
                } else {
                    compressor.compressFile(urlToCompress: videoURL, outputURL: outputURL) { (url) in
                        do {
                            guard let mediaData = try? Data(contentsOf: url) else { return }
                            print("File size after compression: \(Double(mediaData.count / 1048576)) mb")
                            self.mediaData = mediaData
                            self.thumbnailData = mediaData
                        } catch let error {
                            print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
                        }
                    }
                }
            }
//        } else {
//            print("Media already set")
//        }
    }
    
}

// MARK: - UI
private extension SendToViewController {
    func setupLayout() {
        view.backgroundColor = Theme.ultraLightGray
        view.addSubviews([tableView, cancelButton, sendButton])
        
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 16, left: 16, bottom: 0, right: 0))
        
        tableView.anchor(top: cancelButton.bottomAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 16, left: 16, bottom: 0, right: 16))
        
        sendButton.anchor(top: nil, leading: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 24, right: 0), size: .init(width: 200, height: 56))
        sendButton.layer.cornerRadius = 28
        sendButton.anchorCenterXToSuperview()

    }
    
    @objc func cancelButtonTapped() {
        passBackMediaData = mediaData
        passBackSelectedNames = selectedNames
        delegate?.passBack(from: self)
        navigationController?.popViewController(animated: false)
    }
    
    @objc func sendButtonTapped() {
        print("🤶\(#function)")
        let sendToUsers: [ChatWithFriend] = UserController.shared.allChatsWithFriends.filter({
           selectedNames.contains($0.friend.username)
        })
        
        print(sendToUsers.map({ $0.friend.username }))
        
        var type: MessageType = .none
        if image != nil {
            type = .photo
        } else if videoURL != nil {
            type = .video
        }
        
        self.view.window!.rootViewController?.dismiss(animated: false) {
            self.setStatusBar(hidden: false)
            for (_, chat) in sendToUsers {
                chat.isSending = true
                chat.lastSenderUid = UserController.shared.currentUser!.uid
            }
            
            NotificationCenter.default.post(name: .sendingMesssage, object: nil)
            
            let message = Message(senderUid: UserController.shared.currentUser!.uid, status: .sending, messageType: type)
            
            StorageService.shared.saveMediaToStorage(data: self.mediaData!, thumbnailData: self.thumbnailData!, for: message, completion: { (message, error) in
                if let error = error {
                    print(error)
                    return
                }
                print("Media Uploaded")
                guard let message = message else {
                    print("Message is nil")
                    return
                }
                
                for (friend, chat) in sendToUsers {
                    chat.isSending = true
                    chat.lastSenderUid = UserController.shared.currentUser!.uid
                    let dbs = DatabaseService()
                    print("Sending to \(friend.username)")
                    dbs.sendMessage(message, from: UserController.shared.currentUser!, to: friend, chat: chat, completion: { (error) in
                        if let error = error {
                            print(error)
                        }
                        print("Sent from DataBaseService")
                    })
                }
            })
            
        }

    }
}

// MARK: - UITableViewDataSource
extension SendToViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tableSection = TableSection(rawValue: section)!
        switch tableSection {
        case .preview:
            return 0
        case .bestFriends:
            return UserController.shared.bestFriendsChats.count
        case .recents:
            return UserController.shared.recentChatsWithFriends.count
        case .friends:
            return UserController.shared.allChatsWithFriends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: SendToPreviewViewCell.reuseIdentifier, for: indexPath) as! SendToPreviewViewCell
            let size = CGSize(width: view.frame.width * previewSizeRatio, height: view.frame.height * previewSizeRatio)
            if let videoURL = videoURL, let containerView = containerView {
                let screenshot = containerView.screenshot()
                cell.configureVideo(videoURL, screenshot)
                cell.playFromBeginning()
            } else if let image = image {
                cell.configurePhoto(image, size: size)
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: SendToCell.reuseIdentifier, for: indexPath) as! SendToCell
        
        
        cell.isSelected = false
        
        var friend: Friend!
        
        let tableSection = TableSection(rawValue: indexPath.section)!
        switch tableSection {
        case .bestFriends where !UserController.shared.bestFriendsChats.isEmpty:
            friend = UserController.shared.bestFriendsChats[indexPath.row].friend
            
        case .recents where !UserController.shared.recentChatsWithFriends.isEmpty:
            friend = UserController.shared.recentChatsWithFriends[indexPath.row].friend
            
        case .friends where !UserController.shared.allChatsWithFriends.isEmpty:
            friend = UserController.shared.allChatsWithFriends[indexPath.row].friend
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        
        cell.textLabel?.text = friend.displayName
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension SendToViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            cancelButtonTapped()
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? SendToCell else {
            return
        }
        
        guard let name = cell.textLabel?.text else { return }
        
        cell.isSelected = !cell.isSelected
        
        if cell.isSelected {
            selectedNames.insert(name)
        } else {
            selectedNames.remove(name)
        }
        
        if selectionsCount > 0 {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.sendButton.alpha = 1
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.sendButton.alpha = 0
            }, completion: nil)
        }
        
        if let sameCell = tableView.visibleCells.filter({
            $0 != cell && name == $0.textLabel?.text
        }).first as? SendToCell {

            sameCell.isSelected = cell.isSelected

            let sameCellIndexPath = tableView.indexPath(for: sameCell)!
//            tableView.reloadRows(at: [sameCellIndexPath], with: .none)
        } else {
        }
        tableView.reloadRows(at: [indexPath], with: .none)

    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0,
                                                        width: tableView.frame.width,
                                                        height: 56))
        
        let label = UILabel()
        label.frame = headerView.frame
        
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = Theme.ultraDarkGray
        
        let tableSection = TableSection(rawValue: section)!
        switch tableSection {
        case .bestFriends where UserController.shared.bestFriendsChats.count > 0:
            label.text = "Best Friends"
        case .recents where UserController.shared.recentChatsWithFriends.count > 0:
            label.text = "Recents"
        case .friends where UserController.shared.allChatsWithFriends.count > 0:
            label.text = "Friends"
        case .preview:
            return nil
            
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let tableSection = TableSection(rawValue: section)!
        switch tableSection {
        case .bestFriends where !UserController.shared.bestFriendsChats.isEmpty:
            return 56
        case .recents where !UserController.shared.recentChatsWithFriends.isEmpty:
            return 56
        case .friends where !UserController.shared.allChatsWithFriends.isEmpty:
            return 56
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return view.frame.height * previewSizeRatio
        }
        return 56
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let cell = cell as? SendToCell else { return }

        let cornerRadius = 12
        var corners: UIRectCorner = []
        
        if indexPath.row == 0
        {
            corners.update(with: .topLeft)
            corners.update(with: .topRight)
        }
        
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
        {
            corners.update(with: .bottomLeft)
            corners.update(with: .bottomRight)
        }
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: cell.bounds,
                                      byRoundingCorners: corners,
                                      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
        cell.layer.mask = maskLayer

        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            switch cell {
            case let cell as SendToCell:
                cell.separatorView(isHidden: true)
                break
            case _:
                break
            }
        } else if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
            switch cell {
            case let cell as SendToCell:
                cell.separatorView(isHidden: false)
                break
            case _:
                break
            }
        }
        
        if indexPath.section == 0 {
            return
        }
        
        guard let name = cell.textLabel?.text else { return }
        if selectedNames.contains(name) {
            cell.isSelected = true
        } else {
            cell.isSelected = false
        }
        
    }
}
