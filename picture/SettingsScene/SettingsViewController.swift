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
import UserNotifications

enum SettingsType: String {
    case username
    case email
    case profilePhoto
    case password
    
    case notifications
    
    case privacyPolicy
    case termsAndCondtions
    case eula
    case openSource
    
    case clearCache
    case resetPassword
    case logout
    case deleteAccount
    case blocked
    case none
}

class SettingsViewController: UIViewController, LoginFlowHandler, UITableViewDelegate, UITableViewDataSource {
    
    private var cacheSizeInMB: Double {
        return (Double(DiggerCache.downloadedFilesSize()) / BinarySize.MB).rounded(.down)
    }
    
    private var sdCacheSizeInMB: Double {
        return (Double(SDImageCache.shared().getSize()) / BinarySize.MB).rounded(.down)
    }
    
    private var cacheString: String {
        return "\(cacheSizeInMB + sdCacheSizeInMB) MB"
    }
    
    private var didChangeProfilePhoto = false {
        didSet {
            if didChangeProfilePhoto {
                UIView.animate(withDuration: 0.25) {
                    self.setCurrentBackButton(title: "Cancel")
                }
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.setCurrentBackButton(title: "")
                    self.saveChangesButton.isEnabled = false
                }
            }
        }
    }
    private let totalHeaderVerticalPadding: CGFloat = 16 + 16 + 16 + 8
    private typealias SectionInfo = (title: String, value: String, type: SettingsType)
    private var user: User? {
        return UserController.shared.currentUser
    }
    
    private let sectionHeaders: [String] = ["", "My Account", "Preferences", "About", "Account Actions"]
    private lazy var sectionInfoDetails: [[SectionInfo]] = [
        [],
        [
            (title: "Username", value: user?.username ?? "", type: .username),
            (title: "Email", value: user?.email ?? "", type: .email),
            (title: "Password", value: "", type: .password),
        ],
        [
            (title: "Notifications", value: isNotificationsEnabled ? "On" : "Off", type: .notifications)
        ],
        [
            (title: "Privacy Policy", value: "", type: .privacyPolicy),
            (title: "Terms & Conditions", value: "", type: .termsAndCondtions),
            (title: "License Agreement", value: "", type: .eula),
            (title: "Open Source Libraries", value: "", type: .openSource),
        ],
        [
            (title: "Clear Cache", value: cacheString, type: .clearCache),
            (title: "Reset Password", value: "", type: .resetPassword),
            (title: "Blocked", value: "", type: .blocked),
            (title: "Log Out", value: "", type: .logout),
            (title: "Delete Account", value: "", type: .deleteAccount),
        ]
    ]
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .white
        return view
    }()
    
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "\(Bundle.appName()) \(Bundle.main.releaseVersionNumberPretty)"
        label.textAlignment = .center
        label.textColor = Theme.textColor
        return label
    }()
    
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
        button.setTitleColor(Theme.buttonBlue, for: .normal)
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

    private var isNotificationsEnabled = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()

        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItem = saveChangesButton
        
        if let profilePhoto = user?.profilePhoto {
            profileImageButton.setImage(profilePhoto, for: .normal)
            self.profileImageButton.isUserInteractionEnabled = true
        } else if let url = URL(string: (user?.profilePhotoUrl)!) {
            self.profileImageButton.sd_setImage(with: url, for: .normal, completed: { (_, _, _, _) in
                self.profileImageButton.isUserInteractionEnabled = true
            })
        }
        
        setIsNotificationsEnabled(completion: { (enabled) in
            self.isNotificationsEnabled = enabled
        })
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionInfoDetails.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionInfoDetails[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "")
        if indexPath.section != 0 {
            
            let sectionInfoDetail = sectionInfoDetails[indexPath.section][indexPath.row]
            
            cell.accessoryType = .disclosureIndicator
            
            switch sectionInfoDetail.type {
            case .email where Auth.auth().currentUser != nil && !(Auth.auth().currentUser?.isEmailVerified)!:
                let warningView = UIImageView(frame: .init(x: 0, y: 0, width: 16, height: 16))
                warningView.image = #imageLiteral(resourceName: "icons8-error").withRenderingMode(.alwaysTemplate)
                warningView.tintColor = Theme.warningYellow
                cell.accessoryView = warningView
            case .username:
                cell.accessoryType = .none
                cell.selectionStyle = .none
            case .notifications:
                if !isNotificationsEnabled {
                    let warningView = UIImageView(frame: .init(x: 0, y: 0, width: 16, height: 16))
                    warningView.image = #imageLiteral(resourceName: "icons8-error").withRenderingMode(.alwaysTemplate)
                    warningView.tintColor = Theme.warningYellow
                    cell.accessoryView = warningView
                    cell.selectionStyle = .default
                } else {
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

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
            
        // MARK: - Preferences
        case .notifications:
            if !isNotificationsEnabled {

                promptToAppSettings(title: "Unable to use notifications", message: "To enable notifications, go to Settings and enable notifications for this app.") { (completed) in
                    NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

                }
            }

        // MARK: - About
        case .privacyPolicy:
            let aboutVC = AboutViewController(type: .privacyPolicy)
            navigationController?.pushViewController(aboutVC, animated: true)
        case .termsAndCondtions:
            let aboutVC = AboutViewController(type: .termsAndConditions)
            navigationController?.pushViewController(aboutVC, animated: true)
        case .eula:
            let aboutVC = AboutViewController(type: .eula)
            navigationController?.pushViewController(aboutVC, animated: true)
        case .openSource:
            let aboutVC = AboutViewController(type: .openSource)
            navigationController?.pushViewController(aboutVC, animated: true)
            
        // MARK: - Account Actions
        case .clearCache:
            alert(alertTitle: "Clear Cache", alertMessage: "Are you sure you want to clear your cache?", actionTitle: "Clear") { (clear) in
                if clear {
                    FileManager.default.clearAllCache()
                    DispatchQueue.main.async {
                        let cell = tableView.cellForRow(at: indexPath)
                        cell?.detailTextLabel?.text = self.cacheString
                    }
                }
            }
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
            if !(Auth.auth().currentUser?.isEmailVerified)! {
                verifyLogoutActionSheet { (logout, verify) in
                    if logout {
                        self.handleLogout()
                    } else if verify {
                        print("Verify account shit")
                        let editEmailVC = EditEmailViewController.init(navigationTitle: "Email", descriptionText: "You can use this email address to log in,\nor for password recovery.", textFieldText: detail.value, textFieldPlaceholder: "Email address")
                        self.navigationController?.pushViewController(editEmailVC, animated: true)
                    }
                }
 
            } else {
                logoutActionSheet { (success) in
                    if success {
                        self.handleLogout()
                        UIApplication.shared.clearAllNotifications()
                    }
                    
                }
            }
        case .deleteAccount:

            self.deleteAcountAlert { (delete) in
                if delete {
                    print("handle delete acount")
                    let dbs = DatabaseService()
                    dbs.deleteAccount()
                    UIApplication.shared.clearAllNotifications()
                }
            }
        default:
            print(detail.type.rawValue)
        }
        self.deselectCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return header
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        return sectionHeaders[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 128 + changeProfileImageButton.bounds.height + totalHeaderVerticalPadding
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == sectionHeaders.count - 1 {
            return  "\(Bundle.appName()) \(Bundle.main.releaseVersionNumberPretty)"
        }
        
        return nil
    }
}

// MARK: - UI
private extension SettingsViewController {
    func setupLayout() {
        view.addSubviews([versionLabel, tableView])

        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        versionLabel.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: UIEdgeInsets.init(), size: .init(width: 0, height: 44))
    }
    
    func deselectCell() {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }

}

// MARK: - Actions
private extension SettingsViewController {

    @objc private func handleEditProfileImage() {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        presentAlert(alert)
    }
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            presentAlert(alert)
        }
    }
    
    private func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            presentAlert(alert)
        }
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
                    self.didChangeProfilePhoto = false
                    UserController.shared.currentUser?.profilePhoto = image
                })
                
            })
        }
    }
    
    @objc private func willEnterForeground() {
        let preferencesSection = 2
        let notificationsRow = 0
        setIsNotificationsEnabled { (enabled) in
            self.isNotificationsEnabled = enabled
            
            self.sectionInfoDetails[preferencesSection][notificationsRow].value =
                self.isNotificationsEnabled ? "On" : "Off"
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [
                    IndexPath(row: notificationsRow, section: preferencesSection)
                    ], with: .none)
            }
        }
    }
    
    func setIsNotificationsEnabled(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                print("authorized")
                completion(true)
            case .denied:
                print("denied")
                completion(false)
            case .notDetermined:
                print("not determined, ask user for permission now")
                completion(false)
            }
        })
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] ?? info[.originalImage]
        guard let selectedImage = image as? UIImage else { return }
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

        presentAlert(alertController)
    }
}

extension UIViewController {
    func setCurrentBackButton(title: String) {
        guard let vcCount = self.navigationController?.viewControllers.count else {
            return
        }
        
        let priorVCPosition = vcCount - 2
        
        guard priorVCPosition >= 0 else {
            return
        }
        
        self.navigationController?.viewControllers[priorVCPosition].navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: nil)
    }
}
