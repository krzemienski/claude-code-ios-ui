//
//  ChatAttachmentHandler.swift
//  ClaudeCodeUI
//
//  Component 7: Attachment handling and management
//

import UIKit
import Photos
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - ChatAttachmentHandler

/// Handles attachment selection, processing, and management for chat
final class ChatAttachmentHandler: NSObject {
    
    // MARK: - Types
    
    enum AttachmentType {
        case image
        case file
        case code
        case screenshot
    }
    
    struct Attachment {
        let id: String
        let type: AttachmentType
        let data: Data
        let filename: String?
        let mimeType: String?
        let thumbnail: UIImage?
    }
    
    // MARK: - Properties
    
    weak var delegate: ChatAttachmentHandlerDelegate?
    private weak var presentingViewController: UIViewController?
    private var pendingAttachments: [Attachment] = []
    private let maxAttachmentSize: Int = 10 * 1024 * 1024 // 10MB
    
    // MARK: - Initialization
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Show attachment options action sheet
    func showAttachmentOptions() {
        let actionSheet = UIAlertController(title: "Add Attachment", message: nil, preferredStyle: .actionSheet)
        
        // Photo Library
        let photoAction = UIAlertAction(title: "📷 Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        }
        actionSheet.addAction(photoAction)
        
        // Camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "📸 Take Photo", style: .default) { [weak self] _ in
                self?.presentCamera()
            }
            actionSheet.addAction(cameraAction)
        }
        
        // Files
        let filesAction = UIAlertAction(title: "📁 Browse Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        actionSheet.addAction(filesAction)
        
        // Code Snippet
        let codeAction = UIAlertAction(title: "🔤 Code Snippet", style: .default) { [weak self] _ in
            self?.presentCodeSnippetEditor()
        }
        actionSheet.addAction(codeAction)
        
        // Screenshot
        let screenshotAction = UIAlertAction(title: "📱 Take Screenshot", style: .default) { [weak self] _ in
            self?.captureScreenshot()
        }
        actionSheet.addAction(screenshotAction)
        
        // Cancel
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = presentingViewController?.view
            popover.sourceRect = CGRect(x: presentingViewController?.view.bounds.midX ?? 0,
                                       y: presentingViewController?.view.bounds.midY ?? 0,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        presentingViewController?.present(actionSheet, animated: true)
    }
    
    /// Process attachment data
    func processAttachment(data: Data, type: AttachmentType, filename: String? = nil) {
        // Validate size
        guard data.count <= maxAttachmentSize else {
            delegate?.chatAttachmentHandler(self, didFailWithError: AttachmentError.fileTooLarge)
            return
        }
        
        // Create attachment
        let attachment = Attachment(
            id: UUID().uuidString,
            type: type,
            data: data,
            filename: filename,
            mimeType: mimeType(for: type, filename: filename),
            thumbnail: createThumbnail(for: data, type: type)
        )
        
        // Add to pending
        pendingAttachments.append(attachment)
        
        // Notify delegate
        delegate?.chatAttachmentHandler(self, didSelectAttachment: attachment)
    }
    
    /// Handle attachment - wrapper method for validation
    func handleAttachment(_ attachment: Attachment) {
        // Process the attachment through the existing flow
        processAttachment(data: attachment.data, type: attachment.type, filename: attachment.filename)
    }
    
    /// Clear all pending attachments
    func clearAttachments() {
        pendingAttachments.removeAll()
    }
    
    /// Remove specific attachment
    func removeAttachment(id: String) {
        pendingAttachments.removeAll { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        presentingViewController?.present(picker, animated: true)
    }
    
    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = false
        presentingViewController?.present(picker, animated: true)
    }
    
    private func presentDocumentPicker() {
        let types: [UTType] = [.text, .pdf, .image, .data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        presentingViewController?.present(picker, animated: true)
    }
    
    private func presentCodeSnippetEditor() {
        let alert = UIAlertController(title: "Code Snippet", message: "Enter your code:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Language (e.g., swift, python)"
            textField.autocapitalizationType = .none
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Code snippet..."
            textField.autocapitalizationType = .none
        }
        
        let submitAction = UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let language = alert?.textFields?[0].text,
                  let code = alert?.textFields?[1].text,
                  !code.isEmpty,
                  let data = code.data(using: .utf8) else { return }
            
            let filename = "snippet.\(language.isEmpty ? "txt" : language)"
            self?.processAttachment(data: data, type: .code, filename: filename)
        }
        
        alert.addAction(submitAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        presentingViewController?.present(alert, animated: true)
    }
    
    private func captureScreenshot() {
        guard let window = presentingViewController?.view.window else { return }
        
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = screenshot,
           let data = image.jpegData(compressionQuality: 0.8) {
            processAttachment(data: data, type: .screenshot, filename: "screenshot.jpg")
        }
    }
    
    private func mimeType(for type: AttachmentType, filename: String?) -> String {
        switch type {
        case .image:
            return "image/jpeg"
        case .screenshot:
            return "image/jpeg"
        case .code:
            return "text/plain"
        case .file:
            if let filename = filename {
                let ext = (filename as NSString).pathExtension.lowercased()
                switch ext {
                case "pdf": return "application/pdf"
                case "txt": return "text/plain"
                case "json": return "application/json"
                case "xml": return "application/xml"
                default: return "application/octet-stream"
                }
            }
            return "application/octet-stream"
        }
    }
    
    private func createThumbnail(for data: Data, type: AttachmentType) -> UIImage? {
        switch type {
        case .image, .screenshot:
            return UIImage(data: data)?.scaled(to: CGSize(width: 100, height: 100))
        case .code:
            return UIImage(systemName: "doc.text")
        case .file:
            return UIImage(systemName: "doc")
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatAttachmentHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            processAttachment(data: data, type: .image, filename: "image.jpg")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ChatAttachmentHandler: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            let data = try Data(contentsOf: url)
            processAttachment(data: data, type: .file, filename: url.lastPathComponent)
        } catch {
            delegate?.chatAttachmentHandler(self, didFailWithError: error)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled, no action needed
    }
}

// MARK: - ChatAttachmentHandlerDelegate

protocol ChatAttachmentHandlerDelegate: AnyObject {
    func chatAttachmentHandler(_ handler: ChatAttachmentHandler, didSelectAttachment attachment: ChatAttachmentHandler.Attachment)
    func chatAttachmentHandler(_ handler: ChatAttachmentHandler, didFailWithError error: Error)
}

// MARK: - AttachmentError

enum AttachmentError: LocalizedError {
    case fileTooLarge
    case unsupportedType
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "File size exceeds 10MB limit"
        case .unsupportedType:
            return "This file type is not supported"
        case .processingFailed:
            return "Failed to process attachment"
        }
    }
}

// MARK: - UIImage Extension

private extension UIImage {
    func scaled(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}