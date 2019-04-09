//
//  StreamingConnectionCell.swift
//  picture
//
//  Created by Jason Goodney on 4/8/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

enum StreamingConnectionType: String {
    case connect = "Connect"
    case disconnect = "Disconnect"
}

typealias ConnectButtonColors = (connect: UIColor, disconnect: UIColor)

protocol StreamingConnectionCellDelegate: class {
    func connect()
    func disconnect()
}

class EdgeInsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
class StreamingConnectionCell: UITableViewCell, ReuseIdentifiable {
    
    // MARK: - Properties
    var icon: UIImage?
    var buttonColors: ConnectButtonColors = (connect: Theme.buttonBlue, disconnect: Theme.ultraDarkGray)
    
    private var connection: StreamingConnectionType = .connect
    
    weak var delegate: StreamingConnectionCellDelegate?
    
    // MARK: - Views
    private lazy var connectButton: UILabel = {
        let button = UILabel(frame: .zero)
        button.text = connection.rawValue
        button.textColor = .white
//        button.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        button.font = UIFont.systemFont(ofSize: 13)
        button.textAlignment = .center
        button.padding = .init(top: 0, left: 8, bottom: 0, right: 8)
        return button
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private func setupLayout() {

        selectionStyle = .none
        let selectedView = UIView()
        selectedView.backgroundColor = Theme.ultraLightGray
        selectedBackgroundView = selectedView
        
        addSubviews([connectButton])
        
        let height: CGFloat = 24
        connectButton.frame = CGRect(x: 0, y: 0, width: 56, height: height)
        connectButton.layer.cornerRadius = 12
        connectButton.clipsToBounds = true
        
//        connectButton.titleEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        
        accessoryView = connectButton
        
        //updateConnectButton()
    }
    
    func connected() {
        connection = .disconnect
        connectButton.backgroundColor = buttonColors.disconnect
        connectButton.text = connection.rawValue
    }
    
    func disconnected() {
        connection = .connect
        connectButton.backgroundColor = buttonColors.connect
        connectButton.text = connection.rawValue
    }
    
    func updateConnectButton(isConnected: Bool) {
        
        if isConnected {
            connected()
        } else {
            disconnected()
        }
        
//        switch connection {
//        case .connect:
//            connectButton.backgroundColor = buttonColors.connect
//        case .disconnect:
//            connectButton.backgroundColor = buttonColors.disconnect
//        }
//        
//        connectButton.text = connection.rawValue
    }
    
    func connectButtonTapped() {
        if connection == .connect {
            connection = .disconnect
            delegate?.disconnect()
            disconnected()
        } else if connection == .disconnect {
            connection = .connect
            delegate?.connect()
            connected()
        }
        connectButton.layoutIfNeeded()
        
    }
}

extension UILabel {
    private struct AssociatedKeys {
        static var padding = UIEdgeInsets()
    }
    
    public var padding: UIEdgeInsets? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.padding) as? UIEdgeInsets
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.padding, newValue as UIEdgeInsets?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    override open func draw(_ rect: CGRect) {
        if let insets = padding {
            self.drawText(in: rect.inset(by: insets))
        } else {
            self.drawText(in: rect)
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        guard let text = self.text else { return super.intrinsicContentSize }
        
        var contentSize = super.intrinsicContentSize
        var textWidth: CGFloat = frame.size.width
        var insetsHeight: CGFloat = 0.0
        var insetsWidth: CGFloat = 0.0
        
        if let insets = padding {
            insetsWidth += insets.left + insets.right
            insetsHeight += insets.top + insets.bottom
            textWidth -= insetsWidth
        }
        
        let newSize = text.boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                                        options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: self.font], context: nil)
        
        contentSize.height = ceil(newSize.size.height) + insetsHeight
        contentSize.width = ceil(newSize.size.width) + insetsWidth
        
        return contentSize
    }
}
