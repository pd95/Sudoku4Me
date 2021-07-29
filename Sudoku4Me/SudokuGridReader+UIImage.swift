//
//  SudokuGridReader+UIImage.swift
//  SudokuGridReader+UIImage
//
//  Created by Philipp on 29.07.21.
//

import UIKit

extension SudokuGridReader {
    var gridUIImage: UIImage? {
        guard let gridImage = gridImage,
              let cgimg = context.createCGImage(gridImage, from: gridImage.extent)
        else {
            return nil
        }
        return UIImage(cgImage: cgimg)
    }
}
