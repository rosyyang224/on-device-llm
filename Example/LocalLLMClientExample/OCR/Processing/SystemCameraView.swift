import SwiftUI

#if os(iOS)
import UIKit

struct SystemCameraView: UIViewControllerRepresentable {
    var onCapture: (Data?) -> Void

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: SystemCameraView
        init(_ parent: SystemCameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = (info[.originalImage] ?? info[.editedImage]) as? UIImage
            let data = uiImage?.jpegData(compressionQuality: 0.9) ?? uiImage?.pngData()
            parent.onCapture(data)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCapture(nil)
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
#endif
