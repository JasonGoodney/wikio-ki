//
//  Bindable.swift
//  SwipeMatchFirestore
//
//  Created by Jason Goodney on 12/20/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation

class Bindable<T> {
    var value: T? {
        didSet {
            observer?(value)
        }
    }
    
    var observer: ((T?) -> ())?
    
    func bind(observer: @escaping (T?) -> ()) {
        self.observer = observer
    }
}
