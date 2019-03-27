// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension CAGradientLayer {
  static func getGradientLayer(with frame: CGRect, colours: [UIColor], locations: [NSNumber], startPoint: CGPoint, endPoint: CGPoint) -> CAGradientLayer {
    let gradient: CAGradientLayer = CAGradientLayer()
    gradient.frame = frame
    gradient.colors = colours.map({ $0.cgColor })
    gradient.locations = locations
    gradient.startPoint = startPoint
    gradient.endPoint = endPoint
    return gradient
  }
}
