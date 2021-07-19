import PlaygroundSupport
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision


let page = PlaygroundPage.current
page.needsIndefiniteExecution = true

var fileURL: URL
fileURL = Bundle.main.url(forResource: "sudoku-angled", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "sudoku-top-down", withExtension: "jpeg")!
//fileURL = Bundle.main.url(forResource: "Dummy-Rectangle-0", withExtension: "png")!
//fileURL = Bundle.main.url(forResource: "Dummy-Rectangle-30", withExtension: "png")!
//fileURL = Bundle.main.url(forResource: "Dummy-RoundedRectangle", withExtension: "png")!
//fileURL = Bundle.main.url(forResource: "Dummy-NoRectangle", withExtension: "png")!
guard let image = CIImage(contentsOf: fileURL) else {
    fatalError("Image could not be loaded from \(fileURL)")
}
image
let size = image.extent.size


let requestHandler = VNImageRequestHandler(ciImage: image, options: [:])

func handleDetectedRectangles(_ request: VNRequest, error: Error?) {
    print("handleDetectedRectangles:")

    if let rectangles = request.results as? [VNRectangleObservation] {
        print("found \(rectangles.count) rectangles")
        if let rectangle = rectangles.first {
            let scaleTransform = CGAffineTransform(scaleX: size.width, y: size.height)
            let filter = CIFilter.perspectiveCorrection()
            filter.inputImage = image
            filter.topLeft = rectangle.topLeft.applying(scaleTransform)
            filter.topRight = rectangle.topRight.applying(scaleTransform)
            filter.bottomLeft = rectangle.bottomLeft.applying(scaleTransform)
            filter.bottomRight = rectangle.bottomRight.applying(scaleTransform)
            let relevantRectangle = filter.outputImage
            relevantRectangle

            let colorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: CIColor(red: 0, green: 1, blue: 0, alpha: 0.5)])!
            let colorImage = colorGenerator.outputImage?.cropped(to: CGRect(origin: .zero, size: size))

            let perspectiveTransform = CIFilter.perspectiveTransform()
            perspectiveTransform.inputImage = colorImage
            perspectiveTransform.topLeft = rectangle.topLeft.applying(scaleTransform)
            perspectiveTransform.topRight = rectangle.topRight.applying(scaleTransform)
            perspectiveTransform.bottomLeft = rectangle.bottomLeft.applying(scaleTransform)
            perspectiveTransform.bottomRight = rectangle.bottomRight.applying(scaleTransform)
            let colorOverlayImage = perspectiveTransform.outputImage!

            let overlayImageFilter = CIFilter.multiplyCompositing()
            overlayImageFilter.inputImage = colorOverlayImage
            overlayImageFilter.backgroundImage = image
            let overlayImage = overlayImageFilter.outputImage!

            let combineFilter = CIFilter.sourceAtopCompositing()
            combineFilter.inputImage = overlayImage
            combineFilter.backgroundImage = image

            let outputImage = combineFilter.outputImage!
        }
    } else {

    }

    page.finishExecution()
}

let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: handleDetectedRectangles)
try requestHandler.perform([rectDetectRequest])



let outputImage: CIImage?
let blueGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: ["inputColor": CIColor(string: "0.1 0.5 0.8 1.0")])!
let blueImage = blueGenerator.outputImage

let filterM = CIFilter(name: "CIMultiplyCompositing", parameters: ["inputImage": blueImage!, "inputBackgroundImage": image])!
outputImage = filterM.outputImage
