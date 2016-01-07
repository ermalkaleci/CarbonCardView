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

public class CarbonCardView: UIView, CarbonCardViewItemDelegate {

    @IBOutlet public weak var delegate: AnyObject?
    @IBOutlet public weak var dataSource: AnyObject? {
        didSet {
            reloadData()
        }
    }
    
    public private(set) var currentItemIndex: UInt = 0
    private var numberOfItems: UInt = 0
    private var cardViewItems = [CarbonCardViewItem]()
    
    @IBInspectable public var visibleItems: UInt = 10
    
    private let transformingFactor: CGFloat = 0.05
    
    public func reloadData() {
        removeAllItems()
        
        currentItemIndex = 0
        numberOfItems = (dataSource?.numberOfItemsInCarbonCardView(self))!
        
        guard numberOfItems > 0 else { return }
        
        for i in 0 ... min(visibleItems, numberOfItems) - 1 {
            if let cardViewItem = dataSource?.carbonCardView(self, itemAtIndex: i) {
                appendCardViewItem(cardViewItem)
            }
        }
        applyTransforms(false)
    }
    
    private func appendCardViewItem(cardViewItem: CarbonCardViewItem) {
        insertSubview(cardViewItem, atIndex: 0)
        cardViewItem.backgroundColor = UIColor.clearColor()
        cardViewItem.alpha = 0
        
        cardViewItems.append(cardViewItem)
        
        cardViewItem.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[cardViewItem]|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: ["cardViewItem": cardViewItem]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(20)-[cardViewItem]|", options: [.AlignAllTop, .AlignAllBottom], metrics: nil, views: ["cardViewItem": cardViewItem]))
    }
    
    private func removeAllItems() {
        guard cardViewItems.count > 0 else { return }
        for i in 0 ... cardViewItems.count - 1 {
            if let cardViewItem: CarbonCardViewItem = cardViewItems[i] {
                cardViewItem.removeFromSuperview()
            }
        }
        cardViewItems.removeAll()
    }
    
    private func applyTransforms(animation: Bool) {
        
        guard cardViewItems.count > 0 else { return }
        
        for i in 0...cardViewItems.count - 1 {
            applyTransformAtIndex(i, animation: animation)
        }
    }
    
    private func applyTransformAtIndex(index: Int, animation: Bool) {
        
        guard cardViewItems.count > index else { return }
        
        if let cardViewItem: CarbonCardViewItem = cardViewItems[index] {
            
            cardViewItem.userInteractionEnabled = false
            
            if index == 0 {
                cardViewItem.delegate = self
                cardViewItem.userInteractionEnabled = true
            }
            
            let k = CGFloat(index) * transformingFactor
            let cardViewHeight = CGRectGetHeight(bounds) - layoutMargins.top - layoutMargins.bottom - cardViewItem.layoutMargins.top - cardViewItem.layoutMargins.bottom
            
            let scale = CGAffineTransformMakeScale(1.0 - k, 1.0 - k)
            let translate = CGAffineTransformMakeTranslation(0, (1-k) * cardViewHeight/2 - cardViewHeight/2 - k * 2 * 20)
            
            let animationBlock = {
                cardViewItem.alpha = 1
                cardViewItem.transform = CGAffineTransformConcat(scale, translate)
            }
            
            if animation == true {
                cardViewItem.springAnimation(animationBlock, completion: nil)
            } else {
                animationBlock()
            }
        }
    }
    
    private func appendAnotherItem() {
        currentItemIndex++
        let remains = numberOfItems - currentItemIndex
        if remains > visibleItems {
            let insertIndex = currentItemIndex + visibleItems - 1
            if let cardViewItem = dataSource?.carbonCardView(self, itemAtIndex: insertIndex) {
                appendCardViewItem(cardViewItem)
                applyTransformAtIndex(cardViewItems.indexOf(cardViewItem)!, animation: false)
                cardViewItem.fadeIn()
            }
        }
    }
    
    // MARK: CarbonCardViewItem delegate
    public func removeCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, direction: CarbonCardViewItemRemoveDirection) {
        cardViewItems.removeAtIndex(cardViewItems.indexOf(carbonCardViewItem)!)
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            carbonCardViewItem.alpha = 0
            
            if direction == CarbonCardViewItemRemoveDirection.Left {
                carbonCardViewItem.center.x = -CGRectGetWidth(self.bounds)/2
            } else {
                carbonCardViewItem.center.x = CGRectGetWidth(self.bounds) * 1.5
            }
        }) { (Bool) -> Void in
            carbonCardViewItem.removeFromSuperview()
            self.appendAnotherItem()
        }
        
        applyTransforms(true)
    }
    
    public func translateCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, point: CGPoint, angle: CGFloat) {
        let animate = carbonCardViewItem.splited || carbonCardViewItem.dragging == false
        transformViewsBehindView(carbonCardViewItem, point: point, angle: angle, animation: animate)
    }
    
    public func carbonCardViewItemSplited(carbonCardViewItem: CarbonCardViewItem) {
        transformViewsBehindView(carbonCardViewItem, point: CGPointMake(0, 0), angle: 0, animation: true)
    }

    private func transformViewsBehindView(carbonCardViewItem: CarbonCardViewItem, point: CGPoint, angle: CGFloat, animation: Bool) {
        guard cardViewItems.count > 1 else { return }
        
        let x = point.x
        let y = point.y
        
        for i in 1...cardViewItems.count - 1 {
            if let cardViewItem: CarbonCardViewItem = cardViewItems[i] {
                
                let k = CGFloat(i) * transformingFactor
                let cardViewHeight = CGRectGetHeight(bounds) - layoutMargins.top - layoutMargins.bottom - cardViewItem.layoutMargins.top - cardViewItem.layoutMargins.bottom
                
                let scale = CGAffineTransformMakeScale(1.0 - k, 1.0 - k)
                let rotation = CGAffineTransformMakeRotation(angle * (1 - k * 2))
                let translate = CGAffineTransformMakeTranslation(0 + x * (1 - k * 2), ((1-k) * cardViewHeight/2 - cardViewHeight/2 - k * 2 * 20) + y * ( 1 - k * 2))
                
                let scaleRotate = CGAffineTransformConcat(scale, rotation)
                if animation == true {
                    cardViewItem.springAnimation({ () -> Void in
                        cardViewItem.transform = CGAffineTransformConcat(scaleRotate, translate)
                        }, completion: nil)
                } else {
                    cardViewItem.transform = CGAffineTransformConcat(scaleRotate, translate)
                }
            }
        }
    }
}

@objc public protocol CarbonCardViewDelegate: NSObjectProtocol {
    optional func carbonCardView(carbonCardView: CarbonCardView, didRemovedCarbonCardViewItem carbonCardViewItem: CarbonCardViewItem)
}

@objc public protocol CarbonCardViewDataSource: NSObjectProtocol {
    func numberOfItemsInCarbonCardView(carbonCardView: CarbonCardView) -> UInt
    func carbonCardView(carbonCardView: CarbonCardView, itemAtIndex index: UInt) -> CarbonCardViewItem
}
