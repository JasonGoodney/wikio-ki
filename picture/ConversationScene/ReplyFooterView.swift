//
//  ReplyFooterView.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

protocol ReplyFooterViewDelegate: class {
    func replyFooterView(cameraButtonTapped sender: UIButton)
}

class ReplyFooterView: UIView {
    
    weak var delegate: ReplyFooterViewDelegate?
    
    lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.setTitle("Reply", for: .normal)
        button.addTarget(self, action: #selector(cameraButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func cameraButtonTapped(_ sender: UIButton) {
        delegate?.replyFooterView(cameraButtonTapped: sender)
    }
    
}

// MARK: - UI
private extension ReplyFooterView {
    func updateView() {
        backgroundColor = .lightGray
        addSubviews(cameraButton)
        setupConstraints()
    }
    
    func setupConstraints() {
        cameraButton.anchorCenterXToSuperview()
        cameraButton.anchorCenterYToSuperview()
    }
}
