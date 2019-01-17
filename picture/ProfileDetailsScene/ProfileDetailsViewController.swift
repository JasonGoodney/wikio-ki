//
//  ProfileDetailsViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/14/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseFirestore

enum ProfileDetailsType: String {
    case bestFriend
    case block
    case unblock
    case report
    case removeFriend
}

class ProfileDetailsViewController: UIViewController {

    private var user: User
    private var isFriend: Bool {
        return addFriendState == .accepted
    }
    private var isBestFriend: Bool
    private var addFriendState: AddFriendState
    
    private typealias SectionInfo = (title: String, value: String, type: ProfileDetailsType)
    private let sectionHeaders: [String] = ["", "", "Privacy & Support"]
    private lazy var sectionInfoDetails: [[SectionInfo]] = [
        [],
        [
            (title: "Best Friend", value: "", type: .bestFriend)
        ],
        [
        UserController.shared.blockedUids.contains(user.uid) ? (title: "Unblock", value: "", type: .unblock) : (title: "Block", value: "", type: .block),
            (title: "Report", value: "", type: .report),
            (title: "Remove Friend", value: "", type: .removeFriend),
        ]
    ]
    
    private let profileImageView: UIButton = {
        let button = ProfileImageButton(height: 128, width: 128)
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        return label
    }()
    
    private lazy var addFriendButton = AddFriendButton(title: "+ Add", addFriendState: .add)
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .white
        view.register(BestFriendDetailCell.self, forCellReuseIdentifier: BestFriendDetailCell.reuseIdentifier)
        return view
    }()
    
    private lazy var header: UIView = {
        let header = UIView()
        header.addSubviews([profileImageView, usernameLabel, addFriendButton])

        profileImageView.anchorCenterXToSuperview()
        profileImageView.anchor(top: header.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        usernameLabel.anchorCenterXToSuperview()
        usernameLabel.anchor(top: profileImageView.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 16, left: 0, bottom: 0, right: 0))
        
        addFriendButton.anchorCenterXToSuperview()
        addFriendButton.anchor(top: usernameLabel.bottomAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 16, left: 0, bottom: 0, right: 0))
        return header
    }()
    
    init(user: User, isBestFriend: Bool = false, addFriendState: AddFriendState = .add) {
        self.user = user
        self.isBestFriend = isBestFriend
        self.addFriendState = addFriendState
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        guard let url = URL(string: user.profilePhotoUrl) else { return }
        profileImageView.sd_setImage(with: url, for: .normal)
        usernameLabel.text = user.username
        
        updateButton(forAddFriendState: addFriendState)
        
        addFriendButton.addTarget(self, action: #selector(addFriendButtonTapped), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 247, green: 247, blue: 247, alpha: 1)
        
    }

    @objc private func addFriendButtonTapped() {
        let dbs = DatabaseService()
        switch addFriendState {
        case .blocked:
            print("Will unblock user")
            defaultAlert(alertTitle: "Unblock \(user.username)?", actionTitle: "Unblock") { (unblocked) in
                if unblocked {
                    dbs.unblock(user: self.user, completion: { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        print("\(self.user.username) unblocked")
                        DispatchQueue.main.async {
                            self.sectionInfoDetails[1][0] = (title: "Block", value: "", type: .block)
                            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                        }
                    })
                }
            }
        default:
            print("Tapped addfriendbutton")
        }
    }
}

// MARK: - UI
private extension ProfileDetailsViewController {
    func setupLayout() {
        view.backgroundColor = .white
        view.addSubviews([tableView])
        
        tableView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    func updateButton(forAddFriendState state: AddFriendState) {
        
        addFriendButton.setTitle(state.rawValue, for: .normal)
        addFriendButton.addFriendState = state
    }
    
    func deselectCell() {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
}

extension ProfileDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionInfoDetails.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return addFriendState == .accepted ? 1 : 0
        case 2 where !isFriend:
            return 2
        case 2:
            return sectionInfoDetails[section].count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        if indexPath.section != 0 {
            let detail = sectionInfoDetails[indexPath.section][indexPath.row]
            
            switch indexPath.section {
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: BestFriendDetailCell.reuseIdentifier, for: indexPath) as! BestFriendDetailCell
                isBestFriend ? cell.toggleOn() : cell.toggleOff()
                cell.textLabel?.text = detail.title
                return cell
                
            case 2:
                cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.accessoryType = .disclosureIndicator
            default:
                ()
            }
            
            cell.textLabel?.text = detail.title
        }
        return cell
    }
}

extension ProfileDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = sectionInfoDetails[indexPath.section][indexPath.row]
        let dbs = DatabaseService()
        
        switch detail.type {
        case .bestFriend:
            let cell = tableView.cellForRow(at: indexPath) as! BestFriendDetailCell
            isBestFriend = !isBestFriend
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.changeBestFriendStatus(isBestFriend: isBestFriend) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                DispatchQueue.main.async {
                    if self.isBestFriend {
                        cell.toggleOn()
                        UserController.shared.bestFriendUids.append(self.user.uid)
                    } else {
                        cell.toggleOff()
                        UserController.shared.bestFriendUids.removeAll(where: { $0 == self.user.uid })
                    }
                    
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
            
        // MARK: - Privacy & Support
        case .unblock:
            print("Will unblock user")
            defaultAlert(alertTitle: "Unblock \(user.username)?", actionTitle: "Unblock") { (unblocked) in
                if unblocked {
                    dbs.unblock(user: self.user, completion: { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        print("\(self.user.username) unblocked")
                        DispatchQueue.main.async {
                            self.sectionInfoDetails[1][0] = (title: "Block", value: "", type: .block)
                            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                        }
                    })
                }
            }
        case .block:
            destructiveAlert(alertTitle: "Are you sure want to block \(user.username)?", actionTitle: "Block") { (blocked) in
                if blocked {
                    dbs.block(user: self.user, completion: { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        if self.isBestFriend {
                            self.changeBestFriendStatus(isBestFriend: false, completion: { (error) in
                                DispatchQueue.main.async {
                                    UserController.shared.bestFriendUids.removeAll(where: { $0 == self.user.uid })
                   UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                }
                            })
                        }
                        UserController.shared.blockedUids.append(self.user.uid)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            }
        case .report:
            ()
        case .removeFriend:
            destructiveAlert(alertTitle: "Are you sure you want to remove \(user.username) as a friend?", actionTitle: "Remove") { (removed) in
                if removed {
                    dbs.removeFriend(self.user, completion: { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        print("Removed friend")
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            }
        }
        
        deselectCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return section == 0 ? header : nil
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : sectionHeaders[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 256 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension ProfileDetailsViewController: AddFriendDelegate {
    func didTapCancelReceivedRequest(cell: AddFriendCell, user: User, state: AddFriendState) {
        
    }
    
    func didTapAddFriendButton(cell: AddFriendCell, user: User, state: AddFriendState) {
        
    }
}

// MARK: - Private Methods
private extension ProfileDetailsViewController {
    func changeBestFriendStatus(isBestFriend: Bool, completion: @escaping ErrorCompletion) {
        let dbs = DatabaseService()
        let document = Firestore.firestore().collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid).collection(DatabaseService.Collection.friends).document(user.uid)
        
        dbs.updateDocument(document, withFields: ["isBestFriend": isBestFriend], completion: completion)

    }
}
