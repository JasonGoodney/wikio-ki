//
//  SendToViewController.swift
//  picture
//
//  Created by Jason Goodney on 2/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class SendToViewController: UIViewController {
    
    enum TableSection: Int {
        case preview = 0, bestFriends, recents, friends
    }
    
    private var selectionsCount = 0
    private var selectedNames: Set<String> = []
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(SendToCell.self, forCellReuseIdentifier: SendToCell.reuseIdentifier)
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
        button.setTitle("Send  ", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.setImage(#imageLiteral(resourceName: "iconfinder_web_9_3924904").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.alpha = 0
        button.backgroundColor = Theme.buttonBlue
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    private var sendToPreviewView: SendToPreviewView!
    private var image: UIImage? = nil
    private var videoURL: URL? = nil
    
    init(image: UIImage) {
        self.sendToPreviewView = SendToPreviewView(image: image)
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    init(videoURL: URL) {
        self.sendToPreviewView = SendToPreviewView(videoURL: videoURL)
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
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
        
        sendToPreviewView.layer.cornerRadius = 12
        sendToPreviewView.clipsToBounds = true
        sendToPreviewView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelButtonTapped)))
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: false)
    }
    
    @objc func sendButtonTapped() {
        print("🤶\(#function)")
        let sendToUsers: [ChatWithFriend] = UserController.shared.allChatsWithFriends.filter({
           selectedNames.contains($0.friend.username)
        })
        
        print(sendToUsers.map({ $0.friend.username }))
        
        let mediaData = image!.jpegData(compressionQuality: Compression.photoQuality)
        let thumbnailData = image!.jpegData(compressionQuality: Compression.thumbnailQuality)
        for (friend, chat) in sendToUsers {
            
            let message = Message(senderUid: UserController.shared.currentUser!.uid, status: .sending, messageType: .photo)
            let dbs = DatabaseService()
            dbs.send(message, from: UserController.shared.currentUser!, to: friend, chat: chat, mediaData: mediaData, thumbnailData: thumbnailData, completion: { (error) in
                if let error = error {
                    print(error)
                }
                print("Sent from DataBaseService")
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
            return 1
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
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: SendToCell.reuseIdentifier, for: indexPath) as! SendToCell
        
        cell.toggleOff()
        
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
        
        cell.textLabel?.text = friend.username
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SendToViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? SendToCell else {
            return
        }
        cell.isChecked = !cell.isChecked
        
        let visibleCells = tableView.visibleCells
        visibleCells.forEach({
            guard let otherCell = $0 as? SendToCell else { return }
            if let name = cell.textLabel?.text, name == otherCell.textLabel?.text  {
                otherCell.isChecked = cell.isChecked
                
                if otherCell.isChecked {
                    selectionsCount += 1
                    selectedNames.insert(name)
                } else {
                    selectionsCount -= 1
                    selectedNames.remove(name)
                }
            }
            
        })
        
        if selectionsCount > 0 {
//            sendButton.isHidden = false
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.sendButton.alpha = 1
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                self.sendButton.alpha = 0
            }, completion: nil)
        }
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
            headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: view.frame.height * 0.25)
            headerView.addSubview(sendToPreviewView)
            sendToPreviewView.frame = CGRect(x: 0, y: 0, width: view.frame.width * 0.25, height: view.frame.height * 0.25)
            sendToPreviewView.center = headerView.center
            return headerView
            
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let tableSection = TableSection(rawValue: section)!
        switch tableSection {
        case .preview:
            return view.frame.height * 0.25
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 0
        }
        return 56
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
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
    }
}
