//
//  LCUIChatAttachmentPreview.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import AVKit
import QuickLook

@available(iOS 16, *)
public struct LCUIChatAttachmentPreview: View {
    @Environment(\.lcuiChatSettings) private var settings
    @Environment(\.dismiss) private var dismiss

    private let attachment: LCUIChatPreviewAttachment
    private let onShare: (URL) -> Void
    // Presented as a sheet over LCUIChatScreenView, so its own banner overlay would be hidden behind us — this view needs one of its own, fed from the same source of truth as the parent screen's
    private let bannerMessage: Text?
    private let onBannerTapped: () -> Void

    public init(
        attachment: LCUIChatPreviewAttachment,
        onShare: @escaping (URL) -> Void = { _ in },
        bannerMessage: Text? = nil,
        onBannerTapped: @escaping () -> Void = {}
    ) {
        self.attachment = attachment
        self.onShare = onShare
        self.bannerMessage = bannerMessage
        self.onBannerTapped = onBannerTapped
    }

    public var body: some View {
        NavigationStack {
            content
                .background(settings.theme.backgroundColor)
                .navigationTitle(attachment.fileName ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onShare(attachment.sourceURL)
                        } label: {
                            settings.icons.attachmentSharing
                        }
                        .tint(settings.theme.primaryColor)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            settings.icons.closingNavigation
                                .imageScale(.medium)
                                .font(.headline)
                        }
                        .tint(settings.theme.primaryColor)
                    }
                }
                .overlay(alignment: .bottom) {
                    if let bannerMessage {
                        LCUIChatErrorBannerView(message: bannerMessage, onTapped: onBannerTapped)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                }
                .animation(.default, value: bannerMessage != nil)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch attachment.kind {
        case .image:
            AsyncImage(url: attachment.sourceURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    LCUIChatFullScreenErrorView(
                        error:
                        LCUIChatError(
                            title: settings.texts.defaultError,
                            subtitle: nil)
                    )
                default:
                    ProgressView().tint(settings.theme.primaryColor)
                }
            }
        case .video:
            VideoPlayer(player: AVPlayer(url: attachment.sourceURL))
        case .document:
            LCUIChatQuickLookView(url: attachment.sourceURL)
        }
    }
}

/// Leaf bridge to `QLPreviewController` for document previews — no SwiftUI-native equivalent exists.
@available(iOS 16, *)
struct LCUIChatQuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

@available(iOS 16, *)
#Preview {
    LCUIChatAttachmentPreview(
        attachment: LCUIChatPreviewAttachment(fileName: "photo.jpg", kind: .image, sourceURL: URL(string: "https://example.com/photo.jpg")!)
    )
    .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("With banner") {
    LCUIChatAttachmentPreview(
        attachment: LCUIChatPreviewAttachment(fileName: "photo.jpg", kind: .image, sourceURL: URL(string: "https://example.com/photo.jpg")!),
        bannerMessage: Text("No connection"),
        onBannerTapped: { print("Banner tapped") }
    )
    .lcuiChatSettings(.init())
}
