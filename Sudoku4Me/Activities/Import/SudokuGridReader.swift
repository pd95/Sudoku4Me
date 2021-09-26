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

    struct CellDetailObservation {
        struct TextObservation: Hashable {
            let textRectangle: VNRectangleObservation
            let text: String
            let adjustedText: String
            let numberRecognized: Int
            let isGood: Bool
        }

        let row: Int
        let column: Int
        let gridRect: CGRect
        let cellImage: CIImage

        var observations: [TextObservation]

        init(row: Int = -1, column: Int = -1, gridRect: CGRect = .zero, cellImage: CIImage = CIImage(), observations: [TextObservation] = []) {
            self.row = row
            self.column = column
            self.gridRect = gridRect
            self.cellImage = cellImage
            self.observations = observations
        }
    }

    @Published private(set) var inputImage = CIImage()
    @Published private(set) var scaledImage = CIImage()
    @Published private(set) var gridRectangleObservation: VNRectangleObservation?
    @Published private(set) var gridImage: CIImage?
    @Published private(set) var cellDetails: [CellDetailObservation] = []
    @Published private(set) var error: ProcessingError?
    @Published private(set) var game: SudokuGame = SudokuGame()

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
        setupCombine()
    }

    deinit {
        cancellables.removeAll()
    }

    func setupCombine() {
        cancellables.removeAll()

        // Setup image processing pipeline
        $inputImage
            .receive(on: processingQueue)
            .compactMap({ image in
                if image.hasMinimumExtent(100, 100) {
                    return image
                }
                return nil
            })
            .map(scaleImage)
            .tryMap(detectRectangle)
            .mapError(mapProcessingError)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: persistError, receiveValue: { [weak self] (image, rectangleObservation) in
                print("🟢 received scaled image and rectangle", rectangleObservation)
                self?.scaledImage = image
                self?.gridRectangleObservation = rectangleObservation
            })
            .store(in: &cancellables)

        Publishers.CombineLatest($scaledImage, $gridRectangleObservation)
            .receive(on: processingQueue)
            .compactMap({ (image: CIImage, rectangleObservation: VNRectangleObservation?) in
                if let rectangleObservation = rectangleObservation, image.hasMinimumExtent(100, 100) {
                    return (image, rectangleObservation)
                }
                return nil
            })
            .tryMap(fixImagePerspective)
            .map({ [weak self] image in
                DispatchQueue.main.async {
                    print("🟢 received grid image")
                    self?.gridImage = image
                }
                return image
            })
            .tryMap(detectTextInCells)
            .mapError(mapProcessingError)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: persistError, receiveValue: { [weak self] (game, gridCells) in
                print("🟢 received game with cell details", game)
                self?.game = game
                self?.cellDetails = gridCells
            })
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

    func reset() {
        print("reset")
        inputImage = .init()
        scaledImage = .init()
        gridRectangleObservation = nil
        gridImage = nil
        cellDetails = []
        game = SudokuGame()

        if error != nil {
            error = nil
            setupCombine()
        }
    }

    func process(data: Data) throws {
        process(image: try loadImage(data))
    }

    func process(image: CIImage) {
        print("process", Thread.isMainThread ? "Main" : "-")
        inputImage = image
    }

    var hasValidInputImage: Bool {
        return inputImage.hasMinimumExtent(100, 100)
    }

    private func loadImage(_ data: Data) throws -> CIImage {
        guard let image = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            throw ProcessingError.imageLoadingError
        }
        return image
    }

    private func scaleImage(_ image: CIImage) -> CIImage {
        print("scaleImage", Thread.isMainThread ? "Main" : "-")
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

    private func detectRectangle(_ image: CIImage) throws -> (CIImage, VNRectangleObservation) {
        print("detectRectangle", Thread.isMainThread ? "Main" : "-", image)
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

        return (image, rectangleObservation)
    }

    private func fixImagePerspective(_ image: CIImage, rectangleObservation: VNRectangleObservation) throws -> CIImage {
        print("fixImagePerspective", Thread.isMainThread ? "Main" : "-", image, rectangleObservation)

        let scaleTransform = CGAffineTransform(scaleX: image.extent.size.width, y: image.extent.size.height)
        let scaledPoints = [rectangleObservation.topLeft, rectangleObservation.bottomLeft, rectangleObservation.bottomRight, rectangleObservation.topRight]
            .map { $0.applying(scaleTransform) }

        // Fix perspective to focus on our single rectangle
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = scaledPoints[0]
        filter.topRight = scaledPoints[3]
        filter.bottomLeft = scaledPoints[1]
        filter.bottomRight = scaledPoints[2]

        guard let gridImage = filter.outputImage else {
            throw ProcessingError.failedToFixRectanglePerspective
        }
        return gridImage
    }

    private func detectTextInCells(_ gridImage: CIImage) -> (SudokuGame, [CellDetailObservation]) {
        print("detectTextInCells", Thread.isMainThread ? "Main" : "-")

        // Clearing previous game and detected grid
        var game = SudokuGame()

        let size: CGSize = gridImage.extent.size
        let border: CGFloat = 20
        let cellWidth = (size.width - border) / 9
        let cellHeight = (size.height - border) / 9
        let cellSize = CGSize(width: cellWidth, height: cellHeight)

        let requestHandler = VNImageRequestHandler(ciImage: gridImage, options: [:])

        var gridCellContent = [CellDetailObservation]()
        var currentCell = CellDetailObservation(row: -1, column: -1, gridRect: .zero, observations: [])

        let recognizeTextRequest = VNRecognizeTextRequest { (request: VNRequest, error: Error?) in
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                gridCellContent.append(currentCell)
                return
            }

            for recognizedText in results {
                for candidateText in recognizedText.topCandidates(3) {
                    let text = candidateText.string
                    if let box = try? candidateText.boundingBox(for: text.startIndex..<text.endIndex) {

                        gridImage.cropped(to: currentCell.gridRect)
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
                                    try game.set(value: value, at: (currentCell.column, currentCell.row))
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        let observation = CellDetailObservation.TextObservation(
                            textRectangle: box,
                            text: String(text[text.startIndex..<text.endIndex]),
                            adjustedText: String(valueString),
                            numberRecognized: Int(valueString) ?? -1,
                            isGood: isGood
                        )
                        currentCell.observations.append(observation)
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
                currentCell = CellDetailObservation(
                    row: row, column: column,
                    gridRect: rect,
                    cellImage: gridImage.cropped(to: rect),
                    observations: []
                )


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

                gridCellContent.append(currentCell)
            }
        }

        return (game, gridCellContent)
    }

    var hasCellDetails: Bool {
        cellDetails.isEmpty == false
    }

    func cellDetail(for position: SudokuGame.GridPosition) -> CellDetailObservation? {
        cellDetails.first(where: { $0.row == position.row && $0.column == position.column })
    }

    func modify(value: SudokuGame.GridValue, at position: SudokuGame.GridPosition) throws {
        try game.set(value: value, at: position)
    }
}
