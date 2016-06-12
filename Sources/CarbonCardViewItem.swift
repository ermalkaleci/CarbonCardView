//  The MIT License (MIT)
//
//  Copyright (c) 2016 Ermal Kaleci
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

@IBDesignable

public class CarbonCardViewItem: UIView {

    public var distanceToSplit: CGFloat = 0
    public var cornerRadius: CGFloat = 0
    public var shadowOffset: CGSize = CGSizeZero
    public var shadowRadius: CGFloat = 0
    public var shadowOpacity: Float = 0
    public var shadowColor: UIColor = UIColor.clearColor()
    
    public weak var delegate: CarbonCardViewItemDelegate?
    
    public private(set) var isSplitted = false
    public private(set) var isDragging = false
    
    private var beginPoint: CGPoint?
    private var angle: CGFloat?
    
    private func updateCard() {
        layer.shadowOffset  = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius  = shadowRadius
        layer.shadowPath    = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.cornerRadius).CGPath
        layer.cornerRadius  = cornerRadius
        
        if let sublayer: CALayer = layer.sublayers?.first {
            sublayer.cornerRadius = cornerRadius
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateCard()
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        beginPoint = touches.first?.locationInView(superview)
        
        if let point = touches.first?.locationInView(self) {
            angle = (point.x - center.x) / CGRectGetWidth(bounds) * 4
        }
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let
            beginPoint  = beginPoint,
            point       = touches.first?.locationInView(superview)
        {
            let movedByX = point.x - beginPoint.x
            let movedByY = point.y - beginPoint.y
            
            let rotationAngle   = movedByX / CGRectGetWidth(bounds) * 0.5
            let rotate          = CGAffineTransformMakeRotation(rotationAngle)
            let translate       = CGAffineTransformMakeTranslation(movedByX, movedByY)
            
            transform = CGAffineTransformConcat(rotate, translate)
            
            if sqrt(pow(movedByX, 2) + pow(movedByY, 2)) > distanceToSplit {
                isSplitted = true
                delegate?.carbonCardViewItemSplited(self)
            } else if isSplitted == false {
                delegate?.translateCarbonCardViewItem(self, point: CGPointMake(movedByX, movedByY), angle: rotationAngle)
            }
        }
        
        // Set dragging: true after calling delegate to animate first movement
        isDragging = true
    }

    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isDragging = false
        
        if let
            beginPoint  = beginPoint,
            point       = touches.first?.locationInView(superview)
        {
            let movedByX = point.x - beginPoint.x
            let movedByY = point.y - beginPoint.y
            
            let direction: CarbonCardViewItemRemoveDirection = movedByX < 0 ? .Left : .Right
            
            if sqrt(pow(movedByX, 2) + pow(movedByY, 2)) > distanceToSplit {
                delegate?.removeCarbonCardViewItem(self, direction: direction)
            } else {
                reset()
            }
        }
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        isDragging = false
        
        if let
            beginPoint  = beginPoint,
            point       = touches?.first?.locationInView(superview)
        {
            let movedByX = point.x - beginPoint.x
            let movedByY = point.y - beginPoint.y
            
            let direction: CarbonCardViewItemRemoveDirection =  movedByX < 0 ? .Left : .Right
            
            if sqrt(pow(movedByX, 2) + pow(movedByY, 2)) > distanceToSplit {
                self.userInteractionEnabled = false
                delegate?.removeCarbonCardViewItem(self, direction: direction)
                return
            }
        }
        reset()
    }
    
    private func reset() {
        delegate?.translateCarbonCardViewItem(self, point: CGPointMake(0, 0), angle: 0)
        
        let rotate      = CGAffineTransformMakeRotation(0)
        let translate   = CGAffineTransformMakeTranslation(0, 0)

        springAnimation({ () -> Void in
            self.transform = CGAffineTransformConcat(rotate, translate)
        })
        { (Bool) -> Void in
            self.isSplitted = false
        }
    }
}

/**
 Remove with moving direction
 
 - Left:  Move left
 - Right: Move right
 */
public enum CarbonCardViewItemRemoveDirection {
    case Left, Right
}

public protocol CarbonCardViewItemDelegate: NSObjectProtocol {
    func removeCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, direction: CarbonCardViewItemRemoveDirection)
    func translateCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, point: CGPoint, angle: CGFloat)
    func carbonCardViewItemSplited(carbonCardViewItem: CarbonCardViewItem)
}

