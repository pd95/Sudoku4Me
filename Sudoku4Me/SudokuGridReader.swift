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

    @Published var inputImage: CIImage = CIImage()
    @Published var rectangleObservation: [CGPoint] = []
    @Published var gridImage: CIImage?
    @Published var cellDetails: [GridCellContent] = []
    @Published var error: ProcessingError?
    @Published var game: SudokuGame = SudokuGame()

    private let processingQueue = DispatchQueue(label: "Sudoku4Me.processingQueue")
    private var cancellables = Set<AnyCancellable>()

    enum ProcessingError: Error {
        case imageLoadingError
        case noRectangleFound
        case multipleRectanglesFound
        case failedToDetectRectangle
        case failedToFixRectanglePerspective
        case genericError(Error)

        var localizedDescription: String {
            switch self {
            case .imageLoadingError:
                return "The image could not be load."
            case .noRectangleFound:
                return "No rectangle was found in the image."
            case .multipleRectanglesFound:
                return "Multiple rectangles have been detected in the image."
            case .failedToDetectRectangle:
                return "Unable to properly detect a rectangle."
            case .failedToFixRectanglePerspective:
                return "Unable to create grid image for the detected rectangle."
            case .genericError(let error):
                return error.localizedDescription
            }
        }
    }

    init() {
        // Setup image processing pipeline
        $inputImage
            .dropFirst()
            .receive(on: processingQueue)
            .map(scaleImage)
            .tryMap(detectRectangle)
            .mapError(mapProcessingError)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: persistError) { [weak self] (image, points) in
                self?.rectangleObservation = points
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($inputImage, $rectangleObservation)
            .filter({ (image: CIImage, points: [CGPoint]) in
                !points.isEmpty && points.count == 4
                && image.extent.width > 100 && image.extent.height > 100
            })
            .tryMap(fixImagePerspective)
            .map({ [weak self] image in
                DispatchQueue.main.async {
                    self?.gridImage = image
                }
                return image
            })
            .tryMap(detectTextInCells)
            .mapError(mapProcessingError)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: persistError) { [weak self] (game, gridCells) in
                print("received game", game)
                self?.game = game
                self?.cellDetails = gridCells
            }
            .store(in: &cancellables)
    }

    private func mapProcessingError(_ error: Error) -> ProcessingError {
        error as? ProcessingError ?? ProcessingError.genericError(error)
    }

    private func persistError(_ completion: Subscribers.Completion<ProcessingError>) {
        if case .failure(let error) = completion {
            print("Error while processing", error.localizedDescription)
            self.error = error
        }
    }

    func process(data: Data) throws {
        process(image: try loadImage(data))
    }

    func process(image: CIImage) {
        inputImage = image
        rectangleObservation = []
        gridImage = nil
        cellDetails = []
        game = SudokuGame()
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

    private func detectRectangle(_ image: CIImage) throws -> (CIImage, [CGPoint]) {
        print("detectRectangle", image)
        var rectangleObservation: VNRectangleObservation? = nil
        var detectionError: ProcessingError? = nil

        // Request handler to detect the rectangle of the puzzle
        let requestHandler = VNImageRequestHandler(ciImage: image, options: [.ciContext: context])
        let rectDetectRequest = VNDetectRectanglesRequest { (request, error) in
            print("handleDetectedRectangles:")
            if let error = error {
                print("error while detecting rectangles: \(error.localizedDescription)")
                detectionError = ProcessingError.genericError(error)
                return
            }

            guard let rectangles = request.results as? [VNRectangleObservation],
                    rectangles.isEmpty == false
            else {
                print("No rectangle detected")
                detectionError = ProcessingError.noRectangleFound
                return
            }

            guard rectangles.count == 1, let rectangle = rectangles.first else {
                print("More than one rectangle detected!")
                detectionError = ProcessingError.multipleRectanglesFound
                return
            }

            rectangleObservation = rectangle
        }

        rectDetectRequest.minimumAspectRatio = 0.8
        rectDetectRequest.maximumAspectRatio = 1.2

        try requestHandler.perform([rectDetectRequest])

        if let detectionError = detectionError {
            throw detectionError
        }

        guard let rectangleObservation = rectangleObservation else {
            throw ProcessingError.failedToDetectRectangle
        }

        return (image, [rectangleObservation.topLeft, rectangleObservation.bottomLeft, rectangleObservation.bottomRight, rectangleObservation.topRight])
    }

    private func fixImagePerspective(_ image: CIImage, points: [CGPoint]) throws -> CIImage {
        print("fixImagePerspective", image, points)
        guard points.count == 4 else {
            throw ProcessingError.failedToFixRectanglePerspective
        }

        let scaleTransform = CGAffineTransform(scaleX: image.extent.size.width, y: image.extent.size.height)
        let scaledPoints = points.map { $0.applying(scaleTransform) }

        // Fix perspective to focus on our single rectangle
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = scaledPoints[0]
        filter.topRight = scaledPoints[3]
        filter.bottomLeft = scaledPoints[1]
        filter.bottomRight = scaledPoints[2]

        gridImage = filter.outputImage!

        guard let gridImage = gridImage else {
            throw ProcessingError.failedToFixRectanglePerspective
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
        var currentCell: (column: Int, row: Int, rect: CGRect) = (-1, -1, .zero)

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
                        print(currentCell.column, currentCell.row, ":", valueString, box.boundingBox.size, isGood ? "🟢" : "🔴")

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
                                    try game.set(at: (currentCell.column, currentCell.row), value: value)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        let cellContent = GridCellContent(
                            row: currentCell.row, column: currentCell.column,
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

        for row in 0..<9 {
            for column in 0..<9 {
                let point = CGPoint(x: CGFloat(column)*cellWidth+border/2, y: CGFloat(8-row)*cellHeight+border/2)
                let rect = CGRect(origin: point, size: cellSize).insetBy(dx: cellWidth/20, dy: cellHeight/20)
                currentCell = (column, row, rect)

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
