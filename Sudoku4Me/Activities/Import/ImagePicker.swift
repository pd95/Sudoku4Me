//
//  ImagePicker.swift
//  ImagePicker
//
//  Created by Philipp on 29.07.21.
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController

    var sourceType: UIImagePickerController.SourceType
    var handleSelectedImage: (UIImage?) -> Void

    init(withSourceType sourceType: UIImagePickerController.SourceType, handler: @escaping (UIImage?) -> Void) {
        self.sourceType = sourceType
        self.handleSelectedImage = handler
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            imagePicker.sourceType = sourceType
        }
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) &&
            uiViewController.sourceType != sourceType
        {
            uiViewController.sourceType = sourceType
        }
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        return coordinator
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.handleSelectedImage(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.handleSelectedImage(editedImage)
            }
            else if let originalImage = info[.originalImage] as? UIImage {
                parent.handleSelectedImage(originalImage)
            }
            else {
                parent.handleSelectedImage(nil)
            }
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    @State static private var image: UIImage?
    static var previews: some View {
        NavigationView {
            ImagePicker(withSourceType: .photoLibrary, handler: { _ in })
        }
    }
}
