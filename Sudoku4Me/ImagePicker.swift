//
//  ImagePicker.swift
//  ImagePicker
//
//  Created by Philipp on 29.07.21.
//

import SwiftUI

extension UIImagePickerController.SourceType: Identifiable {
    public var id: RawValue {
        rawValue
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController

    var sourceType: UIImagePickerController.SourceType
    var chooseAction: (UIImage?) -> Void


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
            parent.chooseAction(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.chooseAction(editedImage)
            }
            else if let originalImage = info[.originalImage] as? UIImage {
                parent.chooseAction(originalImage)
            }
            else {
                parent.chooseAction(nil)
            }
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    @State static private var image: UIImage?
    static var previews: some View {
        NavigationView {
            ImagePicker(sourceType: .photoLibrary, chooseAction: { _ in })
        }
    }
}
