//
//  SettingsViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/23/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseAuth
import SDWebImage

enum SettingsType: String {
    case username
    case email
    case profilePhoto
    case resetPassword
    case logout
    case blocked
    case none
}

class SettingsViewController: UITableViewController, LoginFlowHandler {
    
    private typealias SectionInfo = (title: String, value: String, type: SettingsType)
    private var user: User? {
        return UserController.shared.currentUser
    }
    
    private let sectionHeaders: [String] = ["", "My Account", "Account Actions"]
    private lazy var sectionInfoDetails: [[SectionInfo]] = [
        [],
        [
            (title: "Username", value: user?.username ?? "", type: .username),
            (title: "UID", value: user?.uid ?? "", type: .none),
            (title: "Email", value: user?.email ?? "", type: .email),
        ],
        [
            (title: "Reset Password", value: "", type: .resetPassword),
            (title: "Blocked", value: "", type: .blocked),
            (title: "Log Out", value: "", type: .logout),
        ]
    ]
    
    private let titleLabel = NavigationTitleLabel(title: "Settings")
    private let profileImageButton: UIButton = {
        let button =  ProfileImageButton(height: 128, width: 128)
        button.addTarget(self, action: #selector(handleEditProfileImage), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    private lazy var header: UIView = {
        let header = UIView()
        header.addSubview(profileImageButton)
        let padding: CGFloat = 16
        profileImageButton.anchorCenterXToSuperview()
        profileImageButton.anchorCenterYToSuperview()
    
        
        return header
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .grouped)
        navigationItem.titleView = titleLabel
        
        if let url = URL(string: (user?.profilePhotoUrl)!) {
            profileImageButton.sd_setImage(with: url, for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionInfoDetails.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionInfoDetails[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        if indexPath.section != 0 {
            cell.accessoryType = .disclosureIndicator
            let sectionInfoDetail = sectionInfoDetails[indexPath.section][indexPath.row]
        
            cell.textLabel?.text = sectionInfoDetail.title
            cell.detailTextLabel?.text = sectionInfoDetail.value
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        
        let type = sectionInfoDetails[indexPath.section][indexPath.row].type
        
        switch type {
        case .blocked:
            let blockUsersVC = BlockedUsersViewController()
            navigationController?.pushViewController(blockUsersVC, animated: true)
        case .logout:
            logoutActionSheet { (success) in
                if success {
                    self.handleLogout()
                }
                self.deselectCell()
            }
        default:
            print(type.rawValue)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return header
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        return sectionHeaders[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 128+32
        }
        return UITableView.automaticDimension
    }
}

// MARK: - Actions
private extension SettingsViewController {
//    @objc func handleLogout() {
//        try? Auth.auth().signOut()
//        let registerVC = RegisterViewController()
//        let navVC = UINavigationController(rootViewController: registerVC)
//        present(navVC, animated: true)
//    }
    
    @objc func handleEditProfileImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        //registerViewModel.bindableImage.value = selectedImage
        //registerViewModel.profilePhoto = selectedImage
        profileImageButton.setImage(selectedImage, for: .normal)
        dismiss(animated: true)
    }
}


extension UITableViewController {
    func deselectCell() {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
}
