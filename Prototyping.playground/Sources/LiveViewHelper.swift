import PlaygroundSupport
import SwiftUI

let context = CIContext()

struct ImageFileCellView: View {
    let filename: String
    let comment: String?
    let uiImage: UIImage

    var body: some View {
        VStack {
            Text(filename)
                .font(.headline)
                .padding()
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
            comment.map(Text.init)?.foregroundColor(.secondary).padding()
        }
    }
}

public func setLiveView(filename: String, comment: String? = nil, uiImage: UIImage) {
    print("Showing \(filename)")
    PlaygroundPage.current.setLiveView(
        ImageFileCellView(filename: filename, comment: comment, uiImage: uiImage)
    )
}

public func setLiveView(filename: String, comment: String? = nil, ciImage: CIImage) {
    if let cgimg = context.createCGImage(ciImage, from: ciImage.extent) {

        let uiImage = UIImage(cgImage: cgimg)
        setLiveView(filename: filename, comment: comment, uiImage: uiImage)
    }
}

