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
    
    @IBInspectable public var visibleItems: UInt = 3 {
        willSet {
            guard newValue > 1 else { return }
            self.visibleItems = newValue
        }
    }
    
    @IBInspectable public var distanceToSplit: CGFloat = 80
    
    @IBInspectable public var cardCornerRadius: CGFloat = 4
    @IBInspectable public var cardShadowOffset: CGSize = CGSizeMake(0, 2)
    @IBInspectable public var cardShadowRadius: NSString = "4"
    @IBInspectable public var cardShadowOpacity: NSString = "0.2"
    @IBInspectable public var cardShadowColor: UIColor = UIColor(white: 0, alpha: 0.2)
    
    var marginPosition: CarbonCardViewMarginPosition = .Top
    @IBInspectable public var marginSpace: Int = 20
    
    /// Index of current top item
    public private(set) var currentItemIndex: UInt = 0
    
    /// An array with visible items
    public private(set) var cardViewItems = [CarbonCardViewItem]()
    
    private var numberOfItems: UInt = 0
    private var removingLocked = false
    
    // MARK: Public API
    
    /**
     Reload everything
     */
    public func reloadData() {
        removeAllItems()
        
        currentItemIndex = 0
        numberOfItems = dataSource?.numberOfItemsInCarbonCardView(self) ?? 0
        marginPosition = dataSource?.marginPositionCarbonCardView?(self) ?? .Top
        
        guard numberOfItems > 0 else { return }
        
        for i in 0 ... min(visibleItems, numberOfItems) - 1 {
            if let cardViewItem = dataSource?.carbonCardView(self, itemAtIndex: i) {
                appendCardViewItem(cardViewItem)
            }
        }
        applyTransforms(false)
    }
    
    /**
     Remove first card view item with direction letf or right
     
     - parameter direction: Moving direction (.Left or .Right)
     */
    public func removeFirstCardWithDirection(direction: CarbonCardViewItemRemoveDirection) {
        guard cardViewItems.count > 0 && removingLocked == false else { return }
        removeCarbonCardViewItem(cardViewItems.first!, direction: direction)
        removingLocked = true
    }
    
    // MARK: Private API
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        applyTransforms(false)
    }
    
    private func appendCardViewItem(cardViewItem: UIView) -> CarbonCardViewItem {
        
        // Create the card
        let card = CarbonCardViewItem()
        card.distanceToSplit = distanceToSplit
        card.cornerRadius = cardCornerRadius
        card.shadowOffset = cardShadowOffset
        card.shadowColor = cardShadowColor
        if let opacity: Float = cardShadowOpacity.floatValue {
            card.shadowOpacity = opacity
        }
        if let radius: Float = cardShadowRadius.floatValue {
            card.shadowRadius = CGFloat(radius)
        }
        
        // Append the view into card
        card.addSubview(cardViewItem)
        
        // Setup constraints
        cardViewItem.translatesAutoresizingMaskIntoConstraints = false
        card.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[cardView]|", options: .DirectionMask, metrics: nil, views: ["cardView": cardViewItem]))
        card.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[cardView]|", options: .DirectionMask, metrics: nil, views: ["cardView": cardViewItem]))
        
        insertSubview(card, atIndex: 0)
        card.clipsToBounds = false
        card.alpha = 0
        
        cardViewItems.append(card)
        
        let views = ["card": card]
        
        var metrics = ["top": 0, "bottom": 0, "left": 0, "right": 0]
        
        switch marginPosition {
        case .Top:
            metrics["top"] = marginSpace
        case .Bottom:
            metrics["bottom"] = marginSpace
        case .Left:
            metrics["left"] = marginSpace
        case .Right:
            metrics["right"] = marginSpace
        }
        
        card.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(left)-[card]-(right)-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(top)-[card]-(bottom)-|", options: [.AlignAllTop, .AlignAllBottom], metrics: metrics, views: views))
        
        return card
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
            
            let scale = CGAffineTransformMakeScale(scaleForIndex(index), scaleForIndex(index))
            let translate = self.translateForIndex(index, point: CGPointZero)
            
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
        currentItemIndex += 1
        let remains = numberOfItems - currentItemIndex
        if remains > visibleItems {
            let insertIndex = currentItemIndex + visibleItems - 1
            if let cardViewItem = dataSource?.carbonCardView(self, itemAtIndex: insertIndex) {
                let card = appendCardViewItem(cardViewItem)
                if let index = cardViewItems.indexOf(card) {
                    applyTransformAtIndex(index, animation: false)
                }
                card.fadeIn()
            }
        }
    }
    
    private func transformViewsBehindView(carbonCardViewItem: CarbonCardViewItem, point: CGPoint, angle: CGFloat, animation: Bool) {
        guard cardViewItems.count > 1 else { return }
        
        for i in 1...cardViewItems.count - 1 {
            if let cardViewItem: CarbonCardViewItem = cardViewItems[i] {
                transformCardViewItem(cardViewItem, index: i, point: point, angle: angle, animation: animation)
            }
        }
    }
    
    private func transformCardViewItem(cardViewItem: CarbonCardViewItem, index: Int, point: CGPoint, angle: CGFloat, animation: Bool) {
        
        let scale = CGAffineTransformMakeScale(scaleForIndex(index), scaleForIndex(index))
        let rotation = CGAffineTransformMakeRotation(angle * scaleForIndex(index))
        let translate = self.translateForIndex(index, point: point)
        
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

// MARK: CarbonCardViewItem delegate
extension CarbonCardView {
    
    public func removeCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, direction: CarbonCardViewItemRemoveDirection) {
        guard let index = cardViewItems.indexOf(carbonCardViewItem) else { return }
        
        cardViewItems.removeAtIndex(index)
        
        delegate?.carbonCardView?(self, willRemoveCarbonCardViewItem: carbonCardViewItem)
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            carbonCardViewItem.alpha = 0
            
            if direction == CarbonCardViewItemRemoveDirection.Left {
                carbonCardViewItem.center.x = -CGRectGetWidth(self.bounds)/2
            } else {
                carbonCardViewItem.center.x = CGRectGetWidth(self.bounds) * 1.5
            }
            
        }) { (Bool) -> Void in
            carbonCardViewItem.removeFromSuperview()
            
            self.delegate?.carbonCardView?(self, didRemovedCarbonCardViewItem: carbonCardViewItem)
            
            self.appendAnotherItem()
            
            self.removingLocked = false
        }
        
        applyTransforms(true)
    }
    
    public func translateCarbonCardViewItem(carbonCardViewItem: CarbonCardViewItem, point: CGPoint, angle: CGFloat) {
        let animate: Bool = carbonCardViewItem.isSplitted || carbonCardViewItem.isDragging == false
        transformViewsBehindView(carbonCardViewItem, point: point, angle: angle, animation: animate)
    }
    
    public func carbonCardViewItemSplited(carbonCardViewItem: CarbonCardViewItem) {
        transformViewsBehindView(carbonCardViewItem, point: CGPointZero, angle: 0, animation: true)
    }
}

extension CarbonCardView {
    
    private func easeOut(i: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat) -> CGFloat {
        let t = i / d
        return c * t * t + b
    }
    
    private func translateForIndex(index: Int, point: CGPoint) -> CGAffineTransform {
        let i = CGFloat(index)
        let items = CGFloat(visibleItems)
        
        var cardHeight = (CGRectGetHeight(bounds) - CGFloat(marginSpace))
        
        if marginPosition == .Left || marginPosition == .Right {
            cardHeight = (CGRectGetWidth(bounds) - CGFloat(marginSpace))
        }
        
        let extraMove = cardHeight / 2 * (1 - scaleForIndex(index)) + CGFloat(index) * CGFloat(marginSpace) / CGFloat(visibleItems - 1)
        
        var x = easeOut(items - i, b: 0, c: point.x, d: items)
        var y = easeOut(items - i, b: 0, c: point.y, d: items)
        
        switch marginPosition {
        case .Top:
            y -= extraMove
        case .Bottom:
            y += extraMove
        case .Left:
            x -= extraMove
        case .Right:
            x += extraMove
        }
        
        return CGAffineTransformMakeTranslation(x, y)
    }
    
    private func scaleForIndex(index: Int) -> CGFloat {
        return 1 - CGFloat(index) * 0.4 / CGFloat(visibleItems)
    }
}

@objc public enum CarbonCardViewMarginPosition: Int {
    case Top
    case Bottom
    case Left
    case Right
}

@objc public protocol CarbonCardViewDelegate: NSObjectProtocol {
    
    /**
     This method will be called when card view will begin the remove animation
     
     - parameter carbonCardView:     CarbonCardView instance that contains the card item
     - parameter carbonCardViewItem: CarbonCardViewItem instance which is going to be removed
     */
    optional func carbonCardView(carbonCardView: CarbonCardView, willRemoveCarbonCardViewItem carbonCardViewItem: CarbonCardViewItem)
    
    /**
     This method will be called after card view did finish the remove animation
     
     - parameter carbonCardView:     CarbonCardView instance that contains the card item
     - parameter carbonCardViewItem: CarbonCardViewItem instance which already is removed
     */
    optional func carbonCardView(carbonCardView: CarbonCardView, didRemovedCarbonCardViewItem carbonCardViewItem: CarbonCardViewItem)
}

@objc public protocol CarbonCardViewDataSource: NSObjectProtocol {
    
    /**
     Number of card items for CarbonCardView instance
     
     - parameter carbonCardView: CarbonCardView instance
     
     - returns: Number of items
     */
    func numberOfItemsInCarbonCardView(carbonCardView: CarbonCardView) -> UInt
    
    /**
     CarbonCardViewItem instance at index
     
     - parameter carbonCardView: CarbonCardView instance
     - parameter index:          CarbonCardViewItem index
     
     - returns: CarbonCardViewItem instance at index
     */
    func carbonCardView(carbonCardView: CarbonCardView, itemAtIndex index: UInt) -> UIView
    
    /**
     CarbonCardView items orientation
     
     - parameter carbonCardView: CarbonCardView instance
     
     - returns: Position
     */
    optional func marginPositionCarbonCardView(carbonCardView: CarbonCardView) -> CarbonCardViewMarginPosition
}
