//
//  Extensions.swift
//  Extensions
//
//  Created by Philipp on 29.07.21.
//

import CoreImage
import UIKit

extension CGImagePropertyOrientation {
    // Converting UIImage Orientation to a CGImageOrientation
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError("Unable to convert unknown image orientation")
        }
    }
}

extension UIImage.Orientation {
    // Convenience method to convert to CGImagePropertyOrientation
    var cgOrientation: CGImagePropertyOrientation {
        CGImagePropertyOrientation(self)
    }
}
