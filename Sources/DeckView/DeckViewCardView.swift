//
//  DeckViewCardView.swift
//  RKC
//
//  Created by Kevin Chen on 1/1/23.
//

import UIKit

open class DeckViewCardView: UIView {
    public let contentView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)
                
        let top = contentView.topAnchor.constraint(equalTo: topAnchor)
        let bottom = bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        let left = contentView.leftAnchor.constraint(equalTo: leftAnchor)
        let right = rightAnchor.constraint(equalTo: contentView.rightAnchor)
        
        NSLayoutConstraint.activate([top, bottom, left, right])

    }
}
