//: [Previous](@previous)
//: [Next](@next)

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

var fileURL: URL
fileURL = Bundle.main.url(forResource: "Find-Rectangle/Dummy-NoRectangle", withExtension: "png")!
fileURL = Bundle.main.url(forResource: "Find-Rectangle/Dummy-Rectangle-0", withExtension: "png")!
fileURL = Bundle.main.url(forResource: "Find-Rectangle/Dummy-Rectangle-30", withExtension: "png")!
//fileURL = Bundle.main.url(forResource: "Find-Rectangle/Dummy-RoundedRectangle", withExtension: "png")!
fileURL = Bundle.main.url(forResource: "sudoku-angled", withExtension: "jpeg")!
guard var image = CIImage(contentsOf: fileURL) else {
    fatalError("Image could not be loaded from \(fileURL)")
}

// Reduce size of very big images
let targetWidth = 500.0
if image.extent.width > targetWidth {
    let resizeFilter = CIFilter.lanczosScaleTransform()
    resizeFilter.inputImage = image
    resizeFilter.scale = Float(targetWidth/image.extent.width)
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

func handleDetectedRectangles(_ request: VNRequest, error: Error?) {
    print("handleDetectedRectangles:")
    image

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
        relevantRectangle

        let colorOverlayImage = addOverlay(rectangleObservation: rectangle, color: CIColor(red: 0, green: 1, blue: 0, alpha: 0.3), in: size)

        let combineFilter = CIFilter.sourceAtopCompositing()
        combineFilter.inputImage = colorOverlayImage
        combineFilter.backgroundImage = image

        let highlightedImage = combineFilter.outputImage!

        setLiveView(filename: fileURL.lastPathComponent,
                    comment: "Detected rectangle",
                    ciImage: highlightedImage)
    }
}

let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])
let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: handleDetectedRectangles)
rectDetectRequest.minimumAspectRatio = 0.8
rectDetectRequest.maximumAspectRatio = 1.2
try requestHandler.perform([rectDetectRequest])
