//
//  SettingsViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/23/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import JGProgressHUD
import SDWebImage
import Digger

enum SettingsType: String {
    case username
    case email
    case profilePhoto
    case password
    case clearCache
    case resetPassword
    case logout
    case deleteAccount
    case blocked
    case none
}

class SettingsViewController: UITableViewController, LoginFlowHandler {
    
    private var cacheSizeInMB: Double {
        return (Double(DiggerCache.downloadedFilesSize()) / MB.binarySize).rounded()
    }
    
    private var sdCacheSizeInMB: Double {
        return (Double(SDImageCache.shared().getSize()) / MB.binarySize).rounded()
    }
    
    private var didChangeProfilePhoto = false
    private let totalHeaderVerticalPadding: CGFloat = 16 + 16 + 16 + 8
    private typealias SectionInfo = (title: String, value: String, type: SettingsType)
    private var user: User? {
        return UserController.shared.currentUser
    }
    
    private let sectionHeaders: [String] = ["", "My Account", "Account Actions"]
    private lazy var sectionInfoDetails: [[SectionInfo]] = [
        [],
        [
            (title: "Username", value: user?.username ?? "", type: .username),
            //(title: "UID", value: user?.uid ?? "", type: .none),
            (title: "Email", value: user?.email ?? "", type: .email),
            (title: "Password", value: "", type: .password),
        ],
        [
            (title: "Clear Cache", value: "\(cacheSizeInMB) MB + \(sdCacheSizeInMB) MB", type: .clearCache),
            (title: "Reset Password", value: "", type: .resetPassword),
            (title: "Blocked", value: "", type: .blocked),
            (title: "Log Out", value: "", type: .logout),
            (title: "Delete Account", value: "", type: .deleteAccount),
        ]
    ]
    
    private let titleLabel = NavigationTitleLabel(title: "Settings")
    private let profileImageButton: UIButton = {
        let button = ProfileImageButton(height: 128, width: 128)
        button.addTarget(self, action: #selector(handleEditProfileImage), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    private lazy var saveChangesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleSaveChanges))
        button.isEnabled = false
        return button
    }()
    
    private lazy var changeProfileImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change Profile Photo", for: .normal)
        button.setTitleColor(WKTheme.buttonBlue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.addTarget(self, action: #selector(handleEditProfileImage), for: .touchUpInside)
        return button
    }()
    
    private lazy var header: UIView = {
        let header = UIView()
        header.addSubviews(profileImageButton, changeProfileImageButton)
        let padding: CGFloat = 16
        profileImageButton.anchorCenterXToSuperview()
        profileImageButton.anchorCenterYToSuperview()
    
        changeProfileImageButton.anchorCenterXToSuperview()
        changeProfileImageButton.anchor(top: profileImageButton.bottomAnchor, leading: nil, bottom: header.bottomAnchor, trailing: nil, padding: UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0))
        return header
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .grouped)
        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItem = saveChangesButton
        
        if let url = URL(string: (user?.profilePhotoUrl)!) {
            self.profileImageButton.sd_setImage(with: url, for: .normal, completed: { (_, _, _, _) in
                self.profileImageButton.isUserInteractionEnabled = true
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .white
        
        DispatchQueue.main.async {
            self.sectionInfoDetails[1] = [
                (title: "Username", value: self.user?.username ?? "", type: .username),
                
                (title: "Email", value: self.user?.email ?? "", type: .email),
                (title: "Password", value: "", type: .password),
            ]
            self.tableView.reloadData()
        }
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
            
            let sectionInfoDetail = sectionInfoDetails[indexPath.section][indexPath.row]
            
            cell.accessoryType = .disclosureIndicator
            
            switch sectionInfoDetail.type {
            case .email where Auth.auth().currentUser != nil && !(Auth.auth().currentUser?.isEmailVerified)!:
                let warningView = UIImageView(frame: .init(x: 0, y: 0, width: 16, height: 16))
                warningView.image = #imageLiteral(resourceName: "icons8-error").withRenderingMode(.alwaysTemplate)
                warningView.tintColor = WKTheme.errorRed
                cell.accessoryView = warningView
            case .username:
                cell.accessoryType = .none
                cell.selectionStyle = .none
            case .deleteAccount:
                cell.textLabel?.textColor = .red
            default:
                ()
            }
        
            cell.textLabel?.text = sectionInfoDetail.title
            cell.detailTextLabel?.text = sectionInfoDetail.value
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let detail = sectionInfoDetails[indexPath.section][indexPath.row]
        
        switch detail.type {
        // MARK: - My Account
        case .username:
            ()
        case .email:
            let editEmailVC = EditEmailViewController.init(navigationTitle: "Email", descriptionText: "You can use this email address to log in,\nor for password recovery.", textFieldText: detail.value, textFieldPlaceholder: "Email address")
            navigationController?.pushViewController(editEmailVC, animated: true)
        case .password:
            let changePasswordVC = ChangePasswordViewController.init(navigationTitle: "Update Password", descriptionText: "To set a new password, please enter your current password first.", textFieldText: "", textFieldPlaceholder: "Current password")
            navigationController?.pushViewController(changePasswordVC, animated: true)
            
            
        // MARK: - Account Actions
        case .blocked:
            let blockUsersVC = BlockedUsersViewController()
            navigationController?.pushViewController(blockUsersVC, animated: true)
        case .resetPassword:
            if !(Auth.auth().currentUser?.isEmailVerified)! {
                errorAlert(alertTitle: "Your email must be verified to reset your password.", alertMessage: nil) {
                    return
                }
            }
            
            let resetPasswordVC = ResetPasswordViewController.init(navigationTitle: "Reset Password", descriptionText: "Enter the email associated with your\nWikio Ki account.", textFieldText: "", textFieldPlaceholder: "Confirm email")
            navigationController?.pushViewController(resetPasswordVC, animated: true)
        case .logout:
            logoutActionSheet { (success) in
                if success {
                    self.handleLogout()
                }
                
            }
        case .deleteAccount:

            self.deleteAcountAlert { (delete) in
                if delete {
                    print("handle delete acount")
                    let dbs = DatabaseService()
                    dbs.deleteAccount()
                }
            }
        default:
            print(detail.type.rawValue)
        }
        self.deselectCell()
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
            return 128 + changeProfileImageButton.bounds.height + totalHeaderVerticalPadding
        }
        return UITableView.automaticDimension
    }
}

// MARK: - UI
private extension SettingsViewController {
    func setupNavigationBar() {
        
    }
}

// MARK: - Actions
private extension SettingsViewController {

    @objc func handleEditProfileImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    @objc func handleSaveChanges() {
        guard let image = profileImageButton.imageView?.image else { return }
        saveImageToFirebase(image) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Updated profile photo")
        }
    }
    
    private func saveImageToFirebase(_ image: UIImage, completion: @escaping ErrorCompletion) {
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Updating Profile"
        hud.show(in: self.view)
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/images/\(filename)")
        let imageData = image.jpegData(compressionQuality: 0.75) ?? Data()
        ref.putData(imageData, metadata: nil) { (_, error) in
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
                let fields = [User.Keys.profilePhotoUrl: imageUrl]
                
                let dbs = DatabaseService()
                dbs.updateUser(withFields: fields, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    hud.dismiss()
                    //print("updated email for \(UserController.shared.currentUser!.username) to \(email)")
                    UserController.shared.fetchCurrentUser(completion: { (success) in
                        if success {
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
                })
                
            })
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        //registerViewModel.bindableImage.value = selectedImage
        //registerViewModel.profilePhoto = selectedImage
        profileImageButton.setImage(selectedImage, for: .normal)
        self.didChangeProfilePhoto = true
        dismiss(animated: true) {
            self.saveChangesButton.isEnabled = self.didChangeProfilePhoto
        }
    }
}


extension UITableViewController {
    func deselectCell() {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
}

private extension SettingsViewController {
    func deleteAcountAlert(completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?\nThis action cannot be un-done.", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (_) in
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
