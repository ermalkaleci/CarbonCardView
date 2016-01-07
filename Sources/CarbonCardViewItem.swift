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

    @IBInspectable public var cardFillColor: UIColor = UIColor.whiteColor()
    @IBInspectable public var cardStrokeColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable public var cardStrokeWidth: CGFloat = 2 // strokeWidth will divided by 10
    @IBInspectable public var cardCornerRadius: CGFloat = 4
    @IBInspectable public var shadowSize: CGSize = CGSizeMake(0, 2)
    @IBInspectable public var shadowBlur: CGFloat = 4
    @IBInspectable public var shadowColor: UIColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.15)
    
    public var splited = false
    public var dragging = false
    public var delegate: CarbonCardViewItemDelegate?
    
    private var beginPoint: CGPoint?
    private var angle: CGFloat?
    private let distanceToSplit: CGFloat = 60
    
    override public func drawRect(rect: CGRect) {
        let newRect = CGRectMake(
            layoutMargins.left,
            layoutMargins.top,
            CGRectGetWidth(rect) - layoutMargins.left - layoutMargins.right,
            CGRectGetHeight(rect) - layoutMargins.top - layoutMargins.bottom
        )
        super.drawRect(newRect)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextSetShadowWithColor(context, shadowSize, shadowBlur * transform.a, shadowColor.CGColor)
        
        cardFillColor.setFill()
        cardStrokeColor.setStroke()
        
        let bezierPath = UIBezierPath(roundedRect: newRect, cornerRadius: cardCornerRadius)
        bezierPath.lineWidth = cardStrokeWidth/10.0
        bezierPath.fill()
        bezierPath.stroke()
        
        CGContextRestoreGState(context)
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        beginPoint = touches.first?.locationInView(superview)
        
        if let point = touches.first?.locationInView(self) {
            angle = (point.x - center.x) / CGRectGetWidth(bounds) * 4
        }
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let point = touches.first?.locationInView(superview) {
            let movedByX = point.x - (beginPoint?.x)!
            let movedByY = point.y - (beginPoint?.y)!
            
            let rotationAngle = angle! * (abs(movedByX) + abs(movedByY)) / 1000
            let rotate = CGAffineTransformMakeRotation(rotationAngle)
            let translate = CGAffineTransformMakeTranslation(movedByX, movedByY)
            
            transform = CGAffineTransformConcat(rotate, translate)
            
            if sqrt(pow(movedByX, 2) + pow(movedByY, 2)) > distanceToSplit {
                splited = true
                delegate?.carbonCardViewItemSplited(self)
            } else if splited == false {
                delegate?.translateCarbonCardViewItem(self, point: CGPointMake(movedByX, movedByY), angle: rotationAngle)
            }
        }
        
        // Set dragging: true after calling delegate to animate first movement
        dragging = true
    }

    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dragging = false
        
        if let point = touches.first?.locationInView(superview) {
            let movedByX = point.x - (beginPoint?.x)!
            let movedByY = point.y - (beginPoint?.y)!
            
            var direction: CarbonCardViewItemRemoveDirection = .Right
            if (movedByX < 0) {
                direction = .Left
            }
            
            if sqrt(pow(movedByX, 2) + pow(movedByY, 2)) > distanceToSplit {
                delegate?.removeCarbonCardViewItem(self, direction: direction)
            } else {
                reset()
            }
        }
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        dragging = false
        
        if let point = touches?.first?.locationInView(superview) {
            let movedByX = point.x - (beginPoint?.x)!
            let movedByY = point.y - (beginPoint?.y)!
            
            var direction: CarbonCardViewItemRemoveDirection = .Right
            if (movedByX < 0) {
                direction = .Left
            }
            
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
        
        let rotate = CGAffineTransformMakeRotation(0)
        let translate = CGAffineTransformMakeTranslation(0, 0)

        springAnimation({ () -> Void in
            self.transform = CGAffineTransformConcat(rotate, translate)
        })
        { (Bool) -> Void in
            self.splited = false
        }
    }
}

public enum CarbonCardViewItemRemoveDirection {
    case Left, Right
}

public protocol CarbonCardViewItemDelegate: NSObjectProtocol {
    func removeCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, direction: CarbonCardViewItemRemoveDirection)
    func translateCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, point: CGPoint, angle: CGFloat)
    func carbonCardViewItemSplited(carbonCardViewItem: CarbonCardViewItem)
}

