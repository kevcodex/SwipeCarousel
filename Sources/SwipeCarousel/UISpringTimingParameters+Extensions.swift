//  Created by Kevin Chen on 2/21/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import UIKit

internal extension UISpringTimingParameters {
    /// - Parameter dampingRatio: The damping ratio to apply to the spring’s motion. To smoothly decelerate the animation without oscillation, specify a value of 1. Specify values closer to 0 to create less damping and more oscillation.
    /// - Parameter frequencyPeriod: The time interval required to complete one oscillation. This affects the "duration" of the animation.
    /// - Parameter initialVelocity: The initial velocity and direction of the animation, specified as a unit vector. When applying a spring animation to an existing animation, use this parameter to create a smoother transition between the animations. This parameter is specified as a two-dimensional vector to accommodate view movements. For properties that don’t involve two-dimensional motion, only the magnitude of the vector is considered.
    /// A vector with a magnitude of 1.0 corresponds to an initial velocity that would cover the total animation distance in one second. For example, if the total animation distance is 200 points and the view’s initial velocity is 100 points per second, specify a vector with a magnitude of 0.5.
    convenience init(dampingRatio: CGFloat, frequencyPeriod: CGFloat, initialVelocity: CGVector = .zero) {
        let mass: CGFloat = 1
        
        // also known as k, spring constant
        let stiffness = pow(2 * .pi / frequencyPeriod, 2) * mass
        
        // also known as c, damping coefficient
        let damping = 4 * .pi * dampingRatio * mass / frequencyPeriod
        
        self.init(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity)
    }
}
