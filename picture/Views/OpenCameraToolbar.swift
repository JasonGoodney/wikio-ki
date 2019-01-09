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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Camera", style: .plain, target: self, action: #selector(handleOpenCamera)),
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
