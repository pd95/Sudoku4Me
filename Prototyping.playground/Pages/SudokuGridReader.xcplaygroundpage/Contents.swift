//: [Previous](@previous)
//: [Next](@next)

import Foundation
import Combine

var fileURL: URL
fileURL = Bundle.main.url(forResource: "sudoku-angled", withExtension: "jpeg")!
fileURL = Bundle.main.url(forResource: "sudoku-top-down", withExtension: "jpeg")!
fileURL = Bundle.main.url(forResource: "sudoku2", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "sudoku3", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "sudoku4", withExtension: "jpeg")!
guard let data = try? Data(contentsOf: fileURL) else {
    fatalError("Unable to read \(fileURL)")
}
print("Continuing execution")

var reader = SudokuGridReader()

var cancellables = Set<AnyCancellable>()

reader.$gridImage
    .compactMap({$0})
    .sink { image in
        print("received \(image)")
        image.uiImage
    }
    .store(in: &cancellables)

print("Start processing data")
try reader.process(data: data)


reader.$cellDetails
    .filter({ !$0.isEmpty })
    .map {
        $0.filter({ !$0.isGood })
            .map {
                (column: $0.column, row: $0.row, text: $0.text, adjustedText: $0.adjustedText, box: $0.textRectangle.boundingBox.size,
                    image: reader.gridImage!.cropped(to: $0.gridRect).uiImage
                )
            }
    }
    .sink { badCells  in
        print("badCells", badCells)
    }
    .store(in: &cancellables)
