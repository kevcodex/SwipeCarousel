//
//  SwipeCarousel.swift
//  RKC
//
//  Created by Kevin Chen on 12/28/22.
//

import UIKit

public protocol SwipeCarouselDatasource: AnyObject {
    func numberOfItems(in swipeCarousel: SwipeCarousel) -> Int
    func swipeCarousel(_ swipeCarousel: SwipeCarousel, cellForItemAt index: Int) -> SwipeCarouselCardView
}

public protocol SwipeCarouselDelegate: AnyObject {
    func swipeCarouselWillBeginDragging(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView)
    
    func swipeCarouselIsDragging(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView, offset: CGFloat)
    
    func swipeCarouselDidEndDragging(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView)
    
    /// Called after the card has finished animating move
    func swipeCarouselDidCompleteMoving(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView)
    
    func swipeCarousel(_ swipeCarousel: SwipeCarousel, didSelectCardAt index: Int)
}

public extension SwipeCarouselDelegate {
    func swipeCarouselWillBeginDragging(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView) {}
    
    func swipeCarouselIsDragging(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView, offset: CGFloat) {}
    
    func swipeCarouselDidEndDragging(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView) {}
    
    /// Called after the card has finished animating move
    func swipeCarouselDidCompleteMoving(_ swipeCarousel: SwipeCarousel, card: SwipeCarouselCardView) {}
    
    func swipeCarousel(_ swipeCarousel: SwipeCarousel, didSelectCardAt index: Int) {}
}

// Apply offset transform and other transforms to mimic apple a little more
// Handle reuse of many stacks of items

/// A view similar to swiping photos on imessage
open class SwipeCarousel: UIView {
    
    public weak var dataSource: SwipeCarouselDatasource? {
        didSet {
            refresh()
        }
    }
    
    public weak var delegate: SwipeCarouselDelegate?
    
    /// The maximum number of cards in stack on left and right sides (includes center)
    public var maxStack = 5
    
    public var cardWidth: CGFloat = 150 {
        didSet {
            for cardContext in cards {
                cardContext.cardWidthConstraint.constant = cardWidth
            }
        }
    }
    
    public private(set) var cards = [SwipeCarouselCardContext]()
    
    private(set) var currentIndex = 0
    
    private let scaleDenominator: CGFloat = 20
    private let degreesMultiplier: CGFloat = 4
    private let minScaleAmount: CGFloat = 0.75
    /// The distance the card is allowed to travel when panning
    public var maxDistance: CGFloat = 120
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        // Slight hack to center cards in main view due to modified anchor point
        for cardContext in cards {
            cardContext.cardTop.constant = frame.height / 2
            cardContext.cardBottom.constant = -frame.height / 2
        }
    }
    
    private func commonInit() {
        refresh()
    }
    
    public func refresh() {
        guard let dataSource else {
            return
        }
        
        // REMOVE ALL PREVIOUS VIEWS
        while cards.count > 0 {
            let cardContext = cards.removeLast()
            cardContext.card.removeFromSuperview()
        }
        currentIndex = 0
        
        let count = dataSource.numberOfItems(in: self)
        
        for i in 0..<count {
            let card = dataSource.swipeCarousel(self, cellForItemAt: i)
            card.translatesAutoresizingMaskIntoConstraints = false
            
            setupGesture(to: card)
            
            // We want the card rotation to be at center bottom
            // But we want the scale to happen in center
            // Therefore apply an anchor at bottom for whole view
            // but apply center scale on center anchor point for conten view
            card.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            applyTransforms(to: card, multiplier: CGFloat(i))
            
            addSubview(card)
            // To get the order aligned with array
            sendSubviewToBack(card)
            
            let cardAnchor = card.centerXAnchor.constraint(equalTo: centerXAnchor)
            let cardWidth = card.widthAnchor.constraint(equalToConstant: cardWidth)
            let topAnchor = card.topAnchor.constraint(equalTo: topAnchor, constant: frame.height / 2)
            let bottomAnchor = bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -frame.height / 2)
            
            NSLayoutConstraint.activate([
                cardAnchor,
                cardWidth,
                topAnchor,
                bottomAnchor
            ])
            
            // Set out of max count to really small so it animates
            if i >= maxStack {
                applyTransforms(to: card, multiplier: scaleDenominator)
            }
            
            let context = SwipeCarouselCardContext(card: card,
                                                   cardAnchor: cardAnchor,
                                                   cardWidthConstraint: cardWidth,
                                                   cardTop: topAnchor,
                                                   cardBottom: bottomAnchor)
            cards.append(context)
        }
    }
    
    private func setupGesture(to card: SwipeCarouselCardView) {
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(handle))
        gesture.delegate = self
        card.addGestureRecognizer(gesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        card.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handle(panGesture: UIPanGestureRecognizer) {
        
        // Grab only the top card regardless of which card is selected
        guard let cardContext = cards.safe(index: currentIndex) else {
            return
        }
        
        let cardAnchor = cardContext.cardAnchor
        
        let velocity = panGesture.velocity(in: panGesture.view)
        
        let translation = panGesture.translation(in: panGesture.view)
        
        let dx = translation.x
                            
        // To increase distance traveled
        let distanceMultiplier = 1.2
        
        let currentX = dx * distanceMultiplier

        switch panGesture.state {
            
        case .began:
            delegate?.swipeCarouselWillBeginDragging(self, card: cardContext.card)
        case .changed:
                                    
            // If exceeds max bounds then have card come closer and flip subview
            var cardDistance: CGFloat
            if abs(currentX) > maxDistance {
                let raw = currentX / maxDistance
                let remainder = currentX.truncatingRemainder(dividingBy: maxDistance)
                let inverter = currentX > 0 ? 1 : -1
                
                cardDistance = maxDistance * CGFloat(inverter) - remainder
                
                // Keep the card at 0 to prevent inversion
                if abs(raw) > 2 {
                    cardDistance = 0
                }
            } else {
                cardDistance = currentX
            }
            
            // The next predicted index
            let increment = dx < 0 ? 1 : -1
            let nextIndex = currentIndex + increment
            
            // Handle selected moving card
            // Scale moving card according to distance
            // Prevent the card from moving if first or last card
            if nextIndex >= 0 && nextIndex < cards.count {
                let scaleMultiplier = max(minScaleAmount, 1 - abs(dx) / maxDistance * 2)
                let scale = CGAffineTransform(scaleX: 1 * scaleMultiplier, y: 1 * scaleMultiplier)
                cardContext.card.contentView.transform = scale
                
                cardAnchor.constant = cardDistance
            }
            
            if let next = cards.safe(index: nextIndex) {
                insertSubview(next.card, belowSubview: cardContext.card)
                
                if abs(currentX) > maxDistance {
                    insertSubview(cardContext.card, belowSubview: next.card)
                } else {
                    insertSubview(cardContext.card, aboveSubview: next.card)
                }
            }
            
            // Animate all cards as dragging
            let distanceIncrement = dx / (maxDistance * 2)
            animateAllCards(adding: distanceIncrement)
            
            delegate?.swipeCarouselIsDragging(self, card: cardContext.card, offset: currentX)

        case .ended, .cancelled, .failed:
            
            let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
            
            let projectedDX = project(initialVelocity: velocity.x, decelerationRate: decelerationRate)
                        
            let projectedConstraint = currentX + projectedDX

            cardAnchor.isActive = false
            
            let increment = projectedConstraint < 0 ? 1 : -1
            let nextIndex = currentIndex + increment

            // Passes desired point
            if abs(projectedConstraint) > maxDistance,
                let next = cards.safe(index: nextIndex) {
                
                insertSubview(cardContext.card, belowSubview: next.card)
                
                currentIndex = nextIndex
            }
            
            cardAnchor.constant = 0

            let vector = CGVector(dx: velocity.x / projectedDX, dy: 0)
            
            delegate?.swipeCarouselDidEndDragging(self, card: cardContext.card)
            
            animateMovingCard(for: cardContext, with: vector, frequencyPeriod: 0.38) { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.delegate?.swipeCarouselDidCompleteMoving(self, card: cardContext.card)
            }
            
        case .possible:
            break
        @unknown default:
            break
        }
    }
    
    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        
        // Ensure the card tapped is the same as the current index
        guard let card = cards.safe(index: currentIndex)?.card,
              card == gesture.view else {
            return
        }
        
        delegate?.swipeCarousel(self, didSelectCardAt: currentIndex)
    }
    
    // From WWDC
    /// Distance travelled after decelerating to zero velocity at a constant rate.
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }
    
    private func animateAllCards(adding increment: CGFloat) {
        for (i, context) in cards.enumerated() {
            // We want to apply the same transforms as if the new card is in the position
            // E.g. card 2 in array is index 1, but we want the same transforms as if it was index 0
            // So need to set the transform index to start at 1
            let referenceIndex = i - (currentIndex - 1) - 1
            let multiplier = CGFloat(referenceIndex) + increment
                                            
            // Unhide or hide cards that out of range of max visbile
            if i < currentIndex + maxStack && i > currentIndex - maxStack {
                self.applyTransforms(to: context.card, multiplier: multiplier)
            } else {
                self.applyTransforms(to: context.card, multiplier: scaleDenominator)
            }
        }
    }
    
    private func animateMovingCard(for cardContext: SwipeCarouselCardContext, with initialVelocity: CGVector, frequencyPeriod: CGFloat, completion: (() -> Void)? = nil) {
        
        let timing = UISpringTimingParameters(dampingRatio: 1.0,
                                              frequencyPeriod: frequencyPeriod,
                                              initialVelocity: initialVelocity)
        
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
        animator.isInterruptible = false
        
        animator.addAnimations { [weak self] in
            guard let self = self else {
                return
            }

            cardContext.cardAnchor.isActive = true
                        
            self.animateAllCards(adding: 0)
            
            self.layoutIfNeeded()
        }
        
        animator.addCompletion { (position) in
            completion?()
        }
        
        animator.startAnimation()
    }
    
    private func applyTransforms(to card: SwipeCarouselCardView, multiplier: CGFloat) {
        let degrees = (multiplier) * degreesMultiplier
        let rotate = CGAffineTransform(rotationAngle: (degrees * CGFloat.pi / 180))
        
        card.transform = rotate
        
        // Last needs to be smallets and most rotatest
        let scaleMultiplier = 1 - (CGFloat(abs(multiplier)) / scaleDenominator)
        let scale = CGAffineTransform(scaleX: 1 * scaleMultiplier, y: 1 * scaleMultiplier)
        
        // This is to keep the scale anchor in center but the rotation anchor at bottom
        card.contentView.transform = scale
    }
}

// MARK: - Gesture Recognizer Delegate

extension SwipeCarousel: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        // Do not trigger gesture if swiping up or down
        let translation = gesture.translation(in: gesture.view)

        return translation.x != 0
    }

}
