//
//  EditDisplayNameViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/10/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD

class EditDisplayNameViewController: EditSettingViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        settingTextField.autocapitalizationType = .words
        settingTextField.autocorrectionType = .no
        
        delegate = self
        
        saveButton.isEnabled = isValidDisplayName(text: settingTextField.text!)
    }
    
    private func isValidDisplayName(text: String) -> Bool {
        if text.hasPrefix(" ") || text.hasSuffix(" ") {
            return false
        }
        
        let spaces = text.filter({ String($0) == " " })
        if spaces.count > 1 {
            return false
        }
        
        if text.utf16.count > 18 {
            return false
        }
        
        return true
    }

}

extension EditDisplayNameViewController: EditSettingDelegate {
    func settingTextFieldDidChange(_ textField: UITextField, text: String) {
        if textField.text == textFieldText || textField.text == "" {
            print(textFieldText)
            saveButton.isEnabled = false
        } else if let displayName = textField.text,
            displayName != UserController.shared.currentUser?.displayName {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }

        if let text = textField.text, !isValidDisplayName(text: text) {
            saveButton.isEnabled = false
        }
        
    }
    
    func updateChanges() {
        guard let displayName = settingTextField.text else { return }
        UserController.shared.currentUser?.displayName = displayName
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Updating Name"
        hud.show(in: self.view)
        
        let dbs = DatabaseService()
        let docRef = DatabaseService.userReference(forPathUid: UserController.shared.currentUser!.uid)
        let fields = ["displayName": displayName]
        dbs.updateData(docRef, withFields: fields) { (error) in
            
            if let error = error {
                print("Error changing display name: \(error)")
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = "\(error.localizedDescription)"
                hud.dismiss(afterDelay: 2.5)
                return
            }
            
            print("Changed display name")
            hud.dismiss()
            self.saveButton.isEnabled = false
        }
    }
    
    
}
