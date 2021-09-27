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

reader.$gridRectangleObservation
    .dropFirst()
    .compactMap({$0})
    .sink { points in
        print("received rectangle points: \(points)")
    }
    .store(in: &cancellables)

reader.$gridImage
    .dropFirst()
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
    .map({ cellDetails in
        cellDetails.compactMap { cellDetail in
            cellDetail.observations
                    .filter({ $0.isGood == false })
                    .map { observation in
                        (column: cellDetail.column, row: cellDetail.row,
                         text: observation.text, adjustedText: observation.adjustedText, box: observation.textRectangle.boundingBox.size,
                         image: cellDetail.cellImage.uiImage
                        )
                    }
        }
        .filter({ $0.isEmpty == false })
    })
    .sink { badCells  in
        print("badCells", badCells)
    }
    .store(in: &cancellables)
