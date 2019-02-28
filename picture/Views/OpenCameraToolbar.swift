//
//  OpenCameraToolbar.swift
//  picture
//
//  Created by Jason Goodney on 12/24/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SwiftyCam

protocol OpenCameraToolbarDelegate: class {
    func didTapOpenCameraButton()
}

class OpenCameraToolbar: UIToolbar {

    weak var openCameraDelegate: OpenCameraToolbarDelegate?
    
    private lazy var cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-camera-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("  Camera", for: .normal)
        button.setTitleColor(Theme.buttonBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.tintColor = Theme.buttonBlue
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let cameraBarButtonItem = UIBarButtonItem(customView: cameraButton)
        cameraBarButtonItem.customView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleOpenCamera)))
        
        items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            cameraBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleOpenCamera() {
        openCameraDelegate?.didTapOpenCameraButton()
    }
}
