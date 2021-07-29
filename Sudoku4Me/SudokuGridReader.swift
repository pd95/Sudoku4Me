//
//  SudokuGridReader.swift
//  SudokuGridReader
//
//  Created by Philipp on 28.07.21.
//

import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

class SudokuGridReader: ObservableObject {
    let context = CIContext()

    struct GridCellContent {
        let row: Int
        let column: Int
        let gridRect: CGRect
        let textRectangle: VNRectangleObservation
        let text: String
        let adjustedText: String
        let numberRecognized: Int
        let isGood: Bool
    }

    @Published var game: SudokuGame?
    @Published var gridImage: CIImage?
    @Published var cellDetails: [GridCellContent] = []

    private let processingQueue = DispatchQueue(label: "Sudoku4Me.processingQueue")
    private var cancellable: AnyCancellable?

    enum ProcessingError: Error {
        case imageLoadingError
        case detectionFailure(Error)
        case noRectangleFound
        case multipleRectanglesFound
        case failedToDetectRectangle
    }

    func process(data: Data) throws {
        process(image: try loadImage(data))
    }

    func process(image: CIImage) {
        game = nil
        gridImage = nil

        // Setup image processing pipeline
        cancellable = Just(image)
            .receive(on: processingQueue)
            .map(scaleImage)
            .tryMap(detectRectangle)
            .map({ image in
                DispatchQueue.main.async {
                    self.gridImage = image
                }
                return image
            })
            .tryMap(detectTextInCells)
            .map({ (game, gridContent) in
                DispatchQueue.main.async {
                    self.game = game
                    self.cellDetails = gridContent
                }
                return game
            })
            .sink { completion in
                print("completion", completion)
            } receiveValue: { result in
                print("receiveValue", result)
            }
    }

    private func loadImage(_ data: Data) throws -> CIImage {
        guard let image = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            throw ProcessingError.imageLoadingError
        }
        return image
    }

    private func scaleImage(_ image: CIImage) -> CIImage {
        let resultImage: CIImage

        // Reduce maximum image dimension
        let desiredMinDimension = 500.0
        let minDimension = min(image.extent.width, image.extent.height)
        if  desiredMinDimension < minDimension {
            let resizeFilter = CIFilter.lanczosScaleTransform()
            resizeFilter.inputImage = image
            resizeFilter.scale = Float(desiredMinDimension/minDimension)
            resultImage = resizeFilter.outputImage!
        }
        else {
            resultImage = image
        }

        return resultImage
    }

    private func detectRectangle(_ image: CIImage) throws -> CIImage {
        var gridImage: CIImage? = nil
        var detectionError: ProcessingError? = nil
        let size = image.extent.size

        // Request handler to detect the rectangle of the puzzle
        let requestHandler = VNImageRequestHandler(ciImage: image, options: [.ciContext: context])
        let rectDetectRequest = VNDetectRectanglesRequest { (request, error) in
            print("handleDetectedRectangles:")
            if let error = error {
                print("error while detecting rectangles: \(error.localizedDescription)")
                detectionError = ProcessingError.detectionFailure(error)
                return
            }

            guard let rectangles = request.results as? [VNRectangleObservation] else {
                print("No rectangle detected")
                detectionError = ProcessingError.noRectangleFound
                return
            }

            guard rectangles.count == 1, let rectangle = rectangles.first else {
                print("More than one rectangle detected!")
                detectionError = ProcessingError.multipleRectanglesFound
                return
            }

            // Fix perspective to focus on our single rectangle
            let scaleTransform = CGAffineTransform(scaleX: size.width, y: size.height)
            let filter = CIFilter.perspectiveCorrection()
            filter.inputImage = image
            filter.topLeft = rectangle.topLeft.applying(scaleTransform)
            filter.topRight = rectangle.topRight.applying(scaleTransform)
            filter.bottomLeft = rectangle.bottomLeft.applying(scaleTransform)
            filter.bottomRight = rectangle.bottomRight.applying(scaleTransform)

            gridImage = filter.outputImage!
        }

        rectDetectRequest.minimumAspectRatio = 0.8
        rectDetectRequest.maximumAspectRatio = 1.2

        try requestHandler.perform([rectDetectRequest])

        if let detectionError = detectionError {
            throw detectionError
        }

        guard let gridImage = gridImage else {
            throw ProcessingError.failedToDetectRectangle
        }

        return gridImage
    }

    private func detectTextInCells(_ gridImage: CIImage) -> (SudokuGame, [GridCellContent]) {
        print("detectTextInCells")

        // Clearing previous game and detected grid
        var game = SudokuGame()

        let size: CGSize = gridImage.extent.size
        let border: CGFloat = 20
        let cellWidth = (size.width - border) / 9
        let cellHeight = (size.height - border) / 9
        let cellSize = CGSize(width: cellWidth, height: cellHeight)

        let requestHandler = VNImageRequestHandler(ciImage: gridImage, options: [:])

        var gridCellContent = [GridCellContent]()
        var currentCell: (x: Int, y: Int, rect: CGRect) = (-1, -1, .zero)

        let recognizeTextRequest = VNRecognizeTextRequest { (request: VNRequest, error: Error?) in
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            for recognizedText in results {
                for candidateText in recognizedText.topCandidates(3) {
                    let text = candidateText.string
                    if let box = try? candidateText.boundingBox(for: text.startIndex..<text.endIndex) {

                        gridImage.cropped(to: currentCell.rect)
                        let isGood = (0.10...0.75).contains(box.boundingBox.size.width)
                                  && (0.3...0.8).contains(box.boundingBox.size.height)

                        var valueString = text[text.startIndex..<text.endIndex]
                        print(currentCell.x, currentCell.y, ":", valueString, box.boundingBox.size, isGood ? "🟢" : "🔴")

                        if !isGood {
                            usleep(200000)
                        }
                        else {
                            if valueString == "I" || valueString == "i" {
                                valueString = "1"
                            }
                            else if valueString == "O" ||  valueString == "o" {
                                valueString = "0"
                            }
                            if let value = Int(valueString) {
                                do {
                                    try game.set(at: (currentCell.x, 8-currentCell.y), value: value)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        let cellContent = GridCellContent(
                            row: 8-currentCell.y, column: currentCell.x,
                            gridRect: currentCell.rect,
                            textRectangle: box,
                            text: String(text[text.startIndex..<text.endIndex]),
                            adjustedText: String(valueString),
                            numberRecognized: Int(valueString) ?? -1,
                            isGood: isGood
                        )
                        gridCellContent.append(cellContent)
                    }
                }
            }
        }
        recognizeTextRequest.recognitionLevel = .fast
        recognizeTextRequest.usesLanguageCorrection = false
        //recognizeTextRequest.minimumTextHeight = 0.5

        for y in 0..<9 {
            for x in 0..<9 {
                let point = CGPoint(x: CGFloat(x)*cellWidth+border/2, y: CGFloat(y)*cellHeight+border/2)
                let rect = CGRect(origin: point, size: cellSize).insetBy(dx: cellWidth/10, dy: cellHeight/10)
                currentCell = (x, y, rect)

                // Convert to a Vision ROI
                recognizeTextRequest.regionOfInterest = CGRect(
                    x: rect.origin.x / size.width,
                    y: rect.origin.y / size.height,
                    width: rect.size.width / size.width,
                    height: rect.size.height / size.height
                )

                do {
                    try requestHandler.perform([recognizeTextRequest])
                } catch {
                    print("Error while recognizing text: \(error.localizedDescription)")
                }
            }
        }

        return (game, gridCellContent)
    }
}
