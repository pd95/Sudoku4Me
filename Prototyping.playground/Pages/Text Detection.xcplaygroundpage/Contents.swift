//: [Previous](@previous)
//: [Next](@next)

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

import PlaygroundSupport
import SwiftUI

func setLiveView(filename: String, comment: String, ciImage: CIImage, game: SudokuGame? = nil) {
    if let uiImage = ciImage.uiImage {
        PlaygroundPage.current.setLiveView(
            VStack {
                ImageFileCellView(filename: filename, comment: comment, uiImage: uiImage)
                if let game = game {
                    SudokuGridView(game: game,
                                   highlightedRow: .constant(nil),
                                   highlightedColumn: .constant(nil))
                        .padding()
                        .foregroundColor(Color.primary.opacity(0.5))
                        .background(
                            Image(uiImage: uiImage)
                                .resizable()
                                .opacity(0.3)
                                .padding(10)
                        )
                }
            }
            .frame(maxHeight: 700)
        )
    }
}

var fileURL: URL
fileURL = Bundle.main.url(forResource: "sudoku-angled", withExtension: "jpeg")!
fileURL = Bundle.main.url(forResource: "sudoku-top-down", withExtension: "jpeg")!
fileURL = Bundle.main.url(forResource: "sudoku2", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "sudoku3-angled", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "sudoku3", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "sudoku4", withExtension: "jpeg")!
guard var image = CIImage(contentsOf: fileURL, options: [.applyOrientationProperty: true]) else {
    fatalError("Image could not be loaded from \(fileURL)")
}

// Reduce size of very big images
let desiredMaxLength = 500.0
let smallestSide = min(image.extent.width, image.extent.height)
if  desiredMaxLength < smallestSide {
    let resizeFilter = CIFilter.lanczosScaleTransform()
    resizeFilter.inputImage = image
    resizeFilter.scale = Float(desiredMaxLength/smallestSide)
    image = resizeFilter.outputImage!
}

setLiveView(filename: fileURL.lastPathComponent, comment: "Initial file", ciImage: image)
let size = image.extent.size


@discardableResult
func addOverlay(rectangleObservation: VNRectangleObservation, color: CIColor, in bounds: CGSize) -> CIImage? {
    let scaleTransform = CGAffineTransform(scaleX: bounds.width, y: bounds.height)

    let colorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: color])!
    let colorImage = colorGenerator.outputImage?.cropped(to: CGRect(origin: .zero, size: size))

    let perspectiveTransform = CIFilter.perspectiveTransform()
    perspectiveTransform.inputImage = colorImage
    perspectiveTransform.topLeft = rectangleObservation.topLeft.applying(scaleTransform)
    perspectiveTransform.topRight = rectangleObservation.topRight.applying(scaleTransform)
    perspectiveTransform.bottomLeft = rectangleObservation.bottomLeft.applying(scaleTransform)
    perspectiveTransform.bottomRight = rectangleObservation.bottomRight.applying(scaleTransform)
    let colorOverlayImage = perspectiveTransform.outputImage

    return colorOverlayImage
}

func detectTextIn(_ image: CIImage) {
    image
    setLiveView(filename: fileURL.lastPathComponent, comment: "Detected grid", ciImage: image)

    let size: CGSize = image.extent.size
    let border: CGFloat = 20
    let cellWidth = (size.width - border) / 9
    let cellHeight = (size.height - border) / 9
    let cellSize = CGSize(width: cellWidth, height: cellHeight)

    let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
    var currentCell: (x: Int, y: Int, rect: CGRect) = (-1, -1, .zero)
    var game = SudokuGame()

    let recognizeTextRequest = VNRecognizeTextRequest { (request: VNRequest, error: Error?) in
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }

        for recognizedText in results {
            for candidateText in recognizedText.topCandidates(3) {
                let text = candidateText.string
                if let box = try? candidateText.boundingBox(for: text.startIndex..<text.endIndex) {

                    image.cropped(to: currentCell.rect)
                    let isGood = (0.10...0.75).contains(box.boundingBox.size.width)
                              && (0.3...0.8).contains(box.boundingBox.size.height)

                    var valueString = text[text.startIndex..<text.endIndex]
                    print(currentCell.x, currentCell.y, ":", valueString, box.boundingBox.size, isGood ? "????" : "????")

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
                                try game.set(value: value, at: (currentCell.x, 8-currentCell.y))
                            } catch {
                                print(error)
                            }
                        }
                    }
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

    try? game.start()
    setLiveView(filename: fileURL.lastPathComponent,
                comment: "Detected grid",
                ciImage: image,
                game: game)
}



func handleDetectedRectangles(_ request: VNRequest, error: Error?) {
    print("handleDetectedRectangles:")

    guard let rectangles = request.results as? [VNRectangleObservation] else { return }
    print("found \(rectangles.count) rectangles")
    let scaleTransform = CGAffineTransform(scaleX: size.width, y: size.height)
    for rectangle in rectangles {
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = rectangle.topLeft.applying(scaleTransform)
        filter.topRight = rectangle.topRight.applying(scaleTransform)
        filter.bottomLeft = rectangle.bottomLeft.applying(scaleTransform)
        filter.bottomRight = rectangle.bottomRight.applying(scaleTransform)
        let relevantRectangle = filter.outputImage!
        detectTextIn(relevantRectangle)
    }
}

let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: handleDetectedRectangles)
rectDetectRequest.minimumAspectRatio = 0.8
rectDetectRequest.maximumAspectRatio = 1.2
try requestHandler.perform([rectDetectRequest])
