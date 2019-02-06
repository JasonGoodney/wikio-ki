/*Copyright (c) 2016, Andrew Walz.
 
 Redistribution and use in source and binary forms, with or without modification,are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

import UIKit
import SwiftyCam

@objc public enum RecordButtonState : Int {
    case recording, idle, hidden;
}

class RecordButton: SwiftyCamButton {
    
    fileprivate var circleLayer: CALayer!
    fileprivate var progressLayer: CAShapeLayer!
    private var circleBorder: CAShapeLayer!
    private var innerCircle: UIView!
    
    private lazy var arcCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
    private lazy var circularPath = UIBezierPath(arcCenter: arcCenter, radius: (self.frame.size.width) / 2, startAngle: -.pi / 2, endAngle: 2 * .pi, clockwise: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        drawButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        drawButton()
    }
    
    private func drawButton() {
        self.backgroundColor = .clear
        addShadow()
        
        circleBorder = CAShapeLayer()
        circleBorder.backgroundColor = UIColor.clear.cgColor

        circleBorder.borderWidth = 6.0
        circleBorder.borderColor = UIColor.clear.cgColor
        
        circleBorder.bounds = self.bounds
        circleBorder.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        circleBorder.cornerRadius = self.frame.size.width / 2

        layer.addSublayer(circleBorder)
        
        circleBorder.strokeColor = UIColor.white.cgColor
        circleBorder.lineWidth = 6
        circleBorder.fillColor = UIColor.clear.cgColor
        
        circleBorder.path = circularPath.cgPath
        
    }
    
    public func growButton(_ recordDuration: Double) {
        innerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        innerCircle.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        innerCircle.backgroundColor = UIColor.red
        innerCircle.layer.cornerRadius = innerCircle.frame.size.width / 2
        innerCircle.clipsToBounds = true
        
        progressLayer = CAShapeLayer()
        progressLayer.strokeColor = UIColor.red.cgColor
        progressLayer.lineWidth = 6
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .square
        progressLayer.strokeEnd = 0
        
        self.progressLayer.path = self.circularPath.cgPath
        
        layer.insertSublayer(progressLayer, above: circleBorder)
        
        self.addSubview(innerCircle)
        
        UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseOut, animations: {
            self.circularPath = UIBezierPath(arcCenter: self.arcCenter, radius: (self.frame.size.width * 1.352) / 2, startAngle: -.pi / 2, endAngle: 2 * .pi, clockwise: true)
            self.progressLayer.path = self.circularPath.cgPath
            
            self.innerCircle.transform = CGAffineTransform(scaleX: 62.4, y: 62.4)
            self.circleBorder.setAffineTransform(CGAffineTransform(scaleX: 1.352, y: 1.352))
            self.circleBorder.borderWidth = (6 / 1.352)
            self.circleBorder.lineWidth = (6 / 1.352)
            
            
        }, completion:{ (success) in
            self.animateProgress(for: recordDuration)
        })
    }
    
    public func shrinkButton() {
        self.progressLayer.removeAllAnimations()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            
            self.circularPath = UIBezierPath(arcCenter: self.arcCenter, radius: (self.frame.size.width) / 2, startAngle: -.pi / 2, endAngle: 2 * .pi, clockwise: true)
            self.progressLayer.path = self.circularPath.cgPath
            
            self.innerCircle.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.circleBorder.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: 1.0))
            self.circleBorder.borderWidth = 6.0
            self.circleBorder.lineWidth = 6.0

        }, completion: { (success) in
            self.innerCircle.removeFromSuperview()
            self.innerCircle = nil
            
            
        })
    }
    
    private func animateProgress(for duration: Double) {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = 1
        basicAnimation.duration = duration
        basicAnimation.fillMode = .forwards
        basicAnimation.isRemovedOnCompletion = false
        
        progressLayer.add(basicAnimation, forKey: "progress")
    }
    
}
