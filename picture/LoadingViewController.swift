//
//  LoadingViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/18/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD

class LoadingViewController: UIViewController {

    lazy var hud = JGProgressHUD(style: .dark)
    
    init(hudText: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.hud.textLabel.text = hudText
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear

        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)

        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = view.bounds

        blurEffectView.contentView.addSubview(vibrancyEffectView)
        
        hud.show(in: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        hud.dismiss()
    }
}
