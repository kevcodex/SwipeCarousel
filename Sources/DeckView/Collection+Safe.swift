//  Created by Kevin Chen on 5/7/20.
//  Copyright © 2020. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }

    /// A safe function to get element of Collection at index path.
    ///
    /// - Parameter index: Index of element in a collection.
    /// - Returns: Element at a given index. If an index is out of boundary of a collection it will return nil and an assertionFailure.
    func safe(index: Index) -> Iterator.Element? {
        return self[safe: index]
    }
}
