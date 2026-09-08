//
//  LCUIChatAttachmentPickerView.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@available(iOS 16, *)
public struct LCUIChatAttachmentPickerView: View {
    @Environment(\.lcuiChatSettings) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showsCamera = false
    @State private var showsDocumentImporter = false
    private let onPick: (LCUIChatAttachment) -> Void

    private var layout: LCUIChatTheme.Layout { settings.theme.layout }
    private var colors: LCUIChatTheme.Colors { settings.theme.colors }
    private var attachmentIcons: LCUIChatIcons.Attachments { settings.icons.attachments }
    private var attachmentTexts: LCUIChatTexts.Attachments { settings.texts.attachments }

    private enum AttachmentOptions { case camera, gallery, documents }

    private static let rowHeight: CGFloat = 52
    private static let dividerHeight: CGFloat = 1
    private static let glassRowSpacing: CGFloat = 8
    private static let topPadding: CGFloat = 20

    private var rowCount: Int {
        settings.constraints.isCameraNeededForAllowedContentTypes ? 3 : 2
    }

    private var usesLiquidGlassChrome: Bool {
        if #available(iOS 26, *) {
            return layout.prefersLiquidGlass
        }
        return false
    }

    private var rowSpacing: CGFloat {
        usesLiquidGlassChrome ? Self.glassRowSpacing : Self.dividerHeight
    }

    private var contentHeight: CGFloat {
        Self.topPadding + CGFloat(rowCount) * Self.rowHeight + CGFloat(rowCount - 1) * rowSpacing
    }

    private func attachmentLabel(for option: AttachmentOptions) -> some View {
        var title: Text = Text("")
        var icon: Image = .init(systemName: "")
        switch option {
            case .camera:
            title = attachmentTexts.takePhotoOrVideo
            icon = attachmentIcons.camera
        case .gallery:
            title = attachmentTexts.photoLibrary
            icon = attachmentIcons.gallery
        case .documents:
            title = attachmentTexts.browse
            icon = attachmentIcons.documents
        }
        return Label {
                title
            } icon: {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
        }
    }

    private func attachmentRow(for option: AttachmentOptions) -> some View {
        attachmentLabel(for: option)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
            .background(rowBackground)
            .padding(.horizontal, usesLiquidGlassChrome ? 8 : 0)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if #available(iOS 26, *), layout.prefersLiquidGlass {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        if usesLiquidGlassChrome {
            Color.clear
        } else {
            colors.background
        }
    }

    public init(
        onPick: @escaping (LCUIChatAttachment) -> Void
    ) {
        self.onPick = onPick
    }

    public var body: some View {
        VStack(spacing: usesLiquidGlassChrome ? Self.glassRowSpacing : 0) {
            if settings.constraints.isCameraNeededForAllowedContentTypes {
                Button {
                    showsCamera = true
                } label: {
                    attachmentRow(for: .camera)
                }
                .buttonStyle(.plain)
                if !usesLiquidGlassChrome {
                    Divider()
                }
            }

            PhotosPicker(selection: $photosPickerItem, matching: .any(of: [.images, .videos])) {
                attachmentRow(for: .gallery)
            }
            .buttonStyle(.plain)

            if !usesLiquidGlassChrome {
                Divider()
            }

            Button {
                showsDocumentImporter = true
            } label: {
                attachmentRow(for: .documents)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Self.topPadding)
        .foregroundStyle(colors.primary)
        .tint(colors.primary)
        .background(containerBackground)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showsCamera) {
            LCUIChatCameraCaptureView { fileName, data, kind in
                onPick(LCUIChatAttachment(fileName: fileName, data: data, kind: kind))
                dismiss()
            }
            .ignoresSafeArea()
        }
        .fileImporter(isPresented: $showsDocumentImporter, allowedContentTypes: settings.constraints.allowedMimeTypes) { result in
            if case .success(let url) = result, let data = try? Data(contentsOf: url) {
                onPick(LCUIChatAttachment(
                    fileName: url.lastPathComponent,
                    data: data,
                    kind: .document)
                )
            }
            dismiss()
        }
        .onChange(of: photosPickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    onPick(LCUIChatAttachment(
                        fileName: nil,
                        data: data,
                        kind: .image)
                    )
                }
                dismiss()
            }
        }
    }
}

/// Note: this can be skipped for a native solution once the min target is iOS 17.
@available(iOS 16, *)
struct LCUIChatCameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (String?, Data, LCUIChatAttachmentKind) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? ["public.image"]
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        picker.view.backgroundColor = .black
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (String?, Data, LCUIChatAttachmentKind) -> Void

        init(onCapture: @escaping (String?, Data, LCUIChatAttachmentKind) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let videoURL = info[.mediaURL] as? URL, let data = try? Data(contentsOf: videoURL) {
                onCapture(videoURL.chatCaptureFilename, data, .video)
            } else if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 1) {
                onCapture(nil, data, .image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

extension URL {
    var chatCaptureFilename: String? {
        let fullFilename = lastPathComponent
        let components = fullFilename.components(separatedBy: ".")
        guard let fileExtension = components.count > 1 ? components.last : nil, !fileExtension.isEmpty else {
            return fullFilename
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date()) + ".\(fileExtension)"
    }
}

@available(iOS 16, *)
#Preview {
    LCUIChatAttachmentPickerView(onPick: { _ in })
        .lcuiChatSettings(.init())
}
