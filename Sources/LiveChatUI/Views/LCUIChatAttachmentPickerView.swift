//
//  LCUIChatAttachmentPickerView.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@available(iOS 16, *)
public struct LCUIChatAttachmentPickerView: View {
    @Environment(\.lcuiChatSettings) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var pendingSource: LCUIChatPendingAttachmentSource?
    @State private var showsCamera = false
    @State private var showsDocumentImporter = false
    @State private var showsPermissionAlert = false
    @State private var isStaging = false

    private let onPick: (LCUIChatAttachment) -> Void
    private let onError: (LCUIChatAttachmentError) -> Void

    private static let importer = LCUIChatAttachmentImporter()

    private var layout: LCUIChatTheme.Layout { settings.theme.layout }
    private var colors: LCUIChatTheme.Colors { settings.theme.colors }
    private var constraints: LCUIChatConstraints { settings.constraints }
    private var attachmentIcons: LCUIChatIcons.Attachments { settings.icons.attachments }
    private var attachmentTexts: LCUIChatTexts.Attachments { settings.texts.attachments }

    @ScaledMetric private var rowHeight: CGFloat = 52
    @ScaledMetric private var topPadding: CGFloat = 20

    private static let dividerHeight: CGFloat = 1
    private static let glassRowSpacing: CGFloat = 8

    public init(
        onPick: @escaping (LCUIChatAttachment) -> Void,
        onError: @escaping (LCUIChatAttachmentError) -> Void = { _ in }
    ) {
        self.onPick = onPick
        self.onError = onError
    }

    // MARK: - Row availability

    private var isCameraRowVisible: Bool {
        constraints.allowsCameraCapture && UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var isGalleryRowVisible: Bool {
        constraints.photoLibraryFilter != nil
    }

    private var visibleRowCount: Int {
        1 + (isCameraRowVisible ? 1 : 0) + (isGalleryRowVisible ? 1 : 0)
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
        topPadding
            + CGFloat(visibleRowCount) * rowHeight
            + CGFloat(max(0, visibleRowCount - 1)) * rowSpacing
    }

    private var cameraMediaTypes: [String] {
        let available = UIImagePickerController.availableMediaTypes(for: .camera) ?? [UTType.image.identifier]
        let permitted = available.filter { identifier in
            guard let type = UTType(identifier) else { return false }
            if type.conforms(to: .movie) || type.conforms(to: .video) {
                return constraints.allowsVideoContent
            }
            if type.conforms(to: .image) {
                return constraints.allowsImageContent
            }
            return false
        }
        return permitted.isEmpty ? [UTType.image.identifier] : permitted
    }

    // MARK: - Body

    public var body: some View {
        let texts = attachmentTexts
        let icons = attachmentIcons
        let style = AttachmentRow.Style(height: rowHeight, usesLiquidGlassChrome: usesLiquidGlassChrome)

        return VStack(spacing: usesLiquidGlassChrome ? Self.glassRowSpacing : 0) {
            if isCameraRowVisible {
                Button(action: handleCameraTap) {
                    AttachmentRow(title: texts.takePhotoOrVideo, icon: icons.camera, style: style)
                }
                .buttonStyle(.plain)
                if !usesLiquidGlassChrome {
                    Divider()
                }
            }

            if let filter = constraints.photoLibraryFilter {
                PhotosPicker(selection: $photosPickerItem, matching: filter, preferredItemEncoding: .current) {
                    AttachmentRow(title: texts.photoLibrary, icon: icons.gallery, style: style)
                }
                .buttonStyle(.plain)

                if !usesLiquidGlassChrome {
                    Divider()
                }
            }

            Button {
                showsDocumentImporter = true
            } label: {
                AttachmentRow(title: texts.browse, icon: icons.documents, style: style)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, topPadding)
        .foregroundStyle(colors.primary)
        .tint(colors.primary)
        .background(containerBackground)
        .presentationDetents([.height(contentHeight), .large])
        .presentationDragIndicator(.visible)
        .disabled(isStaging)
        .overlay {
            if isStaging {
                stagingOverlay
            }
        }
        .fullScreenCover(isPresented: $showsCamera) {
            LCUIChatCameraCaptureView(
                mediaTypes: cameraMediaTypes,
                onCapture: { capture in
                    // SwiftUI owns this cover, so flipping the binding is the only correct way to
                    // dismiss it. Calling `dismiss(animated:)` on the picker tore the view out
                    // from under SwiftUI and left `showsCamera` stuck at `true`.
                    showsCamera = false
                    pendingSource = LCUIChatPendingAttachmentSource(capture)
                },
                onCancel: { showsCamera = false },
                onFailure: { error in
                    showsCamera = false
                    onError(error)
                    dismiss()
                }
            )
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $showsDocumentImporter,
            allowedContentTypes: constraints.documentPickerContentTypes
        ) { result in
            switch result {
            case .success(let url):
                pendingSource = LCUIChatPendingAttachmentSource(origin: .securityScopedFile(url))
            case .failure(let error):
                LCUIChatAttachmentStore.logger.error(
                    "Document import failed: \(error.localizedDescription, privacy: .public)"
                )
                onError(.unreadable)
                dismiss()
            }
        }
        .alert(attachmentTexts.toGivePermission, isPresented: $showsPermissionAlert) {
            Button(role: .cancel) { } label: { settings.texts.cancel }
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                attachmentTexts.goToSettings
            }
        }
        // `.task(id:)` rather than a bare `Task {}`: SwiftUI cancels it when the identity changes
        // or the sheet goes away, so a half-finished copy cannot outlive the view and call back
        // into a torn-down hierarchy.
        .task(id: photosPickerItem) {
            await handlePhotosPickerItem()
        }
        .task(id: pendingSource) {
            await handlePendingSource()
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

    private var stagingOverlay: some View {
        ZStack {
            colors.background.opacity(0.6)
            ProgressView().tint(colors.primary)
        }
        .ignoresSafeArea()
    }

    // MARK: - Picking

    private func handleCameraTap() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            // `.notDetermined` deliberately falls through: UIImagePickerController raises the
            // system prompt itself, so intercepting it here would ask twice.
            showsPermissionAlert = true
        default:
            showsCamera = true
        }
    }

    private func handlePhotosPickerItem() async {
        guard let item = photosPickerItem else { return }
        await stage {
            guard let transferred = try await item.loadTransferable(type: LCUIChatTransferredFile.self) else {
                throw LCUIChatAttachmentError.unreadable
            }
            return try await Self.importer.finish(
                stagedFile: transferred.url,
                preferredFileName: transferred.originalName,
                allowedContentTypes: constraints.allowedContentTypes,
                maximumByteCount: constraints.maximumAttachmentByteCount
            )
        }
        photosPickerItem = nil
    }

    private func handlePendingSource() async {
        guard let pendingSource else { return }
        await stage {
            switch pendingSource.origin {
            case .securityScopedFile(let url):
                return try await Self.importer.stage(
                    source: url,
                    isSecurityScoped: true,
                    allowedContentTypes: constraints.allowedContentTypes,
                    maximumByteCount: constraints.maximumAttachmentByteCount
                )
            case .cameraVideo(let url):
                return try await Self.importer.finish(
                    stagedFile: url,
                    preferredFileName: LCUIChatAttachmentStore.generatedFileName(
                        contentType: LCUIChatAttachmentStore.contentType(of: url)
                    ),
                    allowedContentTypes: constraints.allowedContentTypes,
                    maximumByteCount: constraints.maximumAttachmentByteCount
                )
            case .cameraPhoto(let image):
                return try await Self.importer.stage(
                    photo: image,
                    maximumByteCount: constraints.maximumAttachmentByteCount
                )
            }
        }
        self.pendingSource = nil
    }

    /// Runs a staging operation, reports its outcome to the host, and dismisses — except when the
    /// task was cancelled, which means the sheet is already going away.
    private func stage(_ operation: () async throws -> LCUIChatAttachment) async {
        isStaging = true
        defer { isStaging = false }
        do {
            let attachment = try await operation()
            guard !Task.isCancelled else {
                attachment.discard()
                return
            }
            onPick(attachment)
        } catch is CancellationError {
            return
        } catch let error as LCUIChatAttachmentError {
            onError(error)
        } catch {
            LCUIChatAttachmentStore.logger.error(
                "Attachment staging failed: \(error.localizedDescription, privacy: .public)"
            )
            onError(.unreadable)
        }
        dismiss()
    }
}

// MARK: - Pending source

/// Wraps a picked source with a fresh identity, so `.task(id:)` re-fires even when the same file is
/// chosen twice — and never has to compare `UIImage` payloads to decide whether the id changed.
private struct LCUIChatPendingAttachmentSource: Equatable, Identifiable {
    enum Origin {
        case securityScopedFile(URL)
        case cameraVideo(URL)
        case cameraPhoto(UIImage)
    }

    let id = UUID()
    let origin: Origin

    init(origin: Origin) {
        self.origin = origin
    }

    @available(iOS 16, *)
    init(_ capture: LCUIChatCameraCaptureView.Capture) {
        switch capture {
        case .video(let url):
            self.init(origin: .cameraVideo(url))
        case .photo(let image):
            self.init(origin: .cameraPhoto(image))
        }
    }

    static func == (lhs: LCUIChatPendingAttachmentSource, rhs: LCUIChatPendingAttachmentSource) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Row

/// A standalone view rather than a method on the picker: `PhotosPicker`'s label builder is a`Sendable` closure
@available(iOS 16, *)
private struct AttachmentRow: View {
    /// Sendable, so the row can be configured from inside `PhotosPicker`'s label closure.
    struct Style: Sendable {
        let height: CGFloat
        let usesLiquidGlassChrome: Bool
    }

    let title: Text
    let icon: Image
    let style: Style

    private static let iconSize: CGFloat = 24
    private static let cornerRadius: CGFloat = 14

    nonisolated init(title: Text, icon: Image, style: Style) {
        self.title = title
        self.icon = icon
        self.style = style
    }

    var body: some View {
        Label {
            title
        } icon: {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: Self.iconSize, height: Self.iconSize)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: style.height)
        .contentShape(Rectangle())
        .background(background)
        .padding(.horizontal, style.usesLiquidGlassChrome ? 8 : 0)
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 26, *), style.usesLiquidGlassChrome {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
    }
}

// MARK: - Camera

/// Note: this can be skipped for a native solution once the min target is iOS 17.
@available(iOS 16, *)
struct LCUIChatCameraCaptureView: UIViewControllerRepresentable {
    let mediaTypes: [String]
    let onCapture: (Capture) -> Void
    let onCancel: () -> Void
    let onFailure: (LCUIChatAttachmentError) -> Void

    enum Capture {
        case video(URL)
        /// Stills arrive as an image, not a file — there is no URL to copy.
        case photo(UIImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = mediaTypes
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        picker.view.backgroundColor = .black
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        context.coordinator.onCapture = onCapture
        context.coordinator.onCancel = onCancel
        context.coordinator.onFailure = onFailure
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel, onFailure: onFailure)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onCapture: (Capture) -> Void
        var onCancel: () -> Void
        var onFailure: (LCUIChatAttachmentError) -> Void

        init(
            onCapture: @escaping (Capture) -> Void,
            onCancel: @escaping () -> Void,
            onFailure: @escaping (LCUIChatAttachmentError) -> Void
        ) {
            self.onCapture = onCapture
            self.onCancel = onCancel
            self.onFailure = onFailure
        }

        // Neither callback dismisses the picker itself: SwiftUI presented it via
        // `.fullScreenCover` and owns its lifetime.
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let videoURL = info[.mediaURL] as? URL {
                // The recording lives in a temp file this picker deletes as it is dismissed, so
                // ownership has to be taken here rather than on a later actor hop — by then the
                // file is gone and every capture fails as unreadable. The move is a rename within
                // the same container, so it costs nothing on the main thread.
                do {
                    onCapture(.video(try LCUIChatAttachmentStore.claim(videoURL)))
                } catch {
                    LCUIChatAttachmentStore.logger.error(
                        "Failed to claim camera recording: \(error.localizedDescription, privacy: .public)"
                    )
                    onFailure(.unreadable)
                }
            } else if let image = info[.originalImage] as? UIImage {
                onCapture(.photo(image))
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

@available(iOS 16, *)
#Preview {
    LCUIChatAttachmentPickerView(onPick: { _ in })
        .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("Images only") {
    LCUIChatAttachmentPickerView(onPick: { _ in }, onError: { print("error: \($0)") })
        .lcuiChatSettings(.init(constraints: .init(allowedContentTypes: [.jpeg, .png])))
}

@available(iOS 16, *)
#Preview("Documents only — no camera or gallery row") {
    LCUIChatAttachmentPickerView(onPick: { _ in })
        .lcuiChatSettings(.init(constraints: .init(allowedContentTypes: [.pdf])))
}
