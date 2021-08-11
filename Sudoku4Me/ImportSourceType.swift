//
//  ImportSourceType.swift
//  ImportSourceType
//
//  Created by Philipp on 11.08.21.
//

import Foundation
import UIKit

enum ImportSourceType: Int, Identifiable, CustomStringConvertible, CaseIterable {
    case camera
    case photoLibrary

    var pickerSourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera:
            return .camera
        case .photoLibrary:
            return .photoLibrary
        }
    }

    var description: String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Photo Library"
        }
    }

    var symbolName: String {
        switch self {
        case .camera:
            return "camera"
        case .photoLibrary:
            return "photo"
        }
    }

    var id: RawValue {
        rawValue
    }

    var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(pickerSourceType)
    }
}
