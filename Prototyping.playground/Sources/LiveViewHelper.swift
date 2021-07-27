import PlaygroundSupport
import SwiftUI

extension CIContext {
    public static let shared = CIContext()
}

extension CIImage {
    public var uiImage: UIImage? {
        guard let cgimg = CIContext.shared.createCGImage(self, from: extent) else {
            return nil
        }
        return UIImage(cgImage: cgimg)
    }
}

public struct ImageFileCellView: View {
    public init(filename: String, comment: String?, uiImage: UIImage) {
        self.filename = filename
        self.comment = comment
        self.uiImage = uiImage
    }

    let filename: String
    let comment: String?
    let uiImage: UIImage

    public var body: some View {
        VStack {
            Text(filename)
                .font(.headline)
                .padding()
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            comment.map(Text.init)?.foregroundColor(.secondary).padding()
        }
        .frame(maxWidth: 400)
    }
}
