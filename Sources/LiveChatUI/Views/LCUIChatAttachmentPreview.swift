//
//  LCUIChatAttachmentPreview.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import Foundation
import SwiftUI
import AVKit
import QuickLook

private func isAttachmentPreviewCancellation(_ error: Error?) -> Bool {
    var underlyingError: NSError? = error as? NSError
    while let error = underlyingError {
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return true
        }
        underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
    }
    return false
}

@available(iOS 16, *)
public struct LCUIChatAttachmentPreview: View {
    @Environment(\.lcuiChatSettings) private var settings
    @Environment(\.dismiss) private var dismiss

    private var colors: LCUIChatTheme.Colors { settings.theme.colors }
    private var attTexts: LCUIChatTexts.Attachments { settings.texts.attachments }
    private var errorTexts: LCUIChatTexts.Errors { settings.texts.errors }

    @State private var failureTracker = LCUIChatPreviewFailureTracker()

    private let attachment: LCUIChatPreviewAttachment
    private let onShare: (URL) -> Void
    /// Called once when an attachment cannot be rendered, with its original remote URL when available.
    private let onPreviewFailure: (URL) -> Void
    // Presented as a sheet over LCUIChatScreenView, so its own banner overlay would be hidden behind us — this view needs one of its own, fed from the same source of truth as the parent screen's
    private let bannerMessage: Text?
    private let onBannerTapped: () -> Void

    public init(
        attachment: LCUIChatPreviewAttachment,
        onShare: @escaping (URL) -> Void = { _ in },
        onPreviewFailure: @escaping (URL) -> Void = { _ in },
        bannerMessage: Text? = nil,
        onBannerTapped: @escaping () -> Void = {}
    ) {
        self.attachment = attachment
        self.onShare = onShare
        self.onPreviewFailure = onPreviewFailure
        self.bannerMessage = bannerMessage
        self.onBannerTapped = onBannerTapped
    }

    public var body: some View {
        NavigationStack {
            content
                .background(colors.background)
                .navigationTitle(attachment.fileName ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onShare(attachment.sourceURL)
                        } label: {
                            settings.icons.attachments.sharing
                        }
                        .tint(colors.primary)
                        .accessibilityLabel(attTexts.share)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            settings.icons.navigation.closing
                                .imageScale(.medium)
                                .font(.headline)
                        }
                        .tint(colors.primary)
                        .accessibilityLabel(settings.texts.back)
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
                case .failure(let error):
                    errorView
                        .onAppear {
                            guard !isAttachmentPreviewCancellation(error) else { return }
                            reportPreviewFailure(for: attachment)
                        }
                default:
                    ProgressView().tint(colors.primary)
                }
            }
        case .video:
            LCUIChatVideoPreview(url: attachment.sourceURL, errorTexts: errorTexts) {
                reportPreviewFailure(for: attachment)
            }
            .id(LCUIChatVideoPreviewIdentity(id: attachment.id, url: attachment.sourceURL))
        case .document:
            if let url = attachment.quickLookURL,
               QLPreviewController.canPreview(url as NSURL) {
                LCUIChatQuickLookView(url: url)
            } else {
                errorView
                    .onAppear { reportPreviewFailure(for: attachment) }
            }
        }
    }

    private var errorView: some View {
        LCUIChatFullScreenErrorView(
            error: LCUIChatError(title: errorTexts.defaultError, subtitle: nil)
        )
    }

    private func reportPreviewFailure(for attachment: LCUIChatPreviewAttachment) {
        guard let fallbackURL = failureTracker.fallbackURLToReport(for: attachment) else { return }
        onPreviewFailure(fallbackURL)
    }
}

struct LCUIChatPreviewFailureTracker {
    private struct Identity: Equatable {
        let id: UUID
        let kind: LCUIChatAttachmentKind
        let sourceURL: URL
        let originalURL: URL?

        init(_ attachment: LCUIChatPreviewAttachment) {
            id = attachment.id
            kind = attachment.kind
            sourceURL = attachment.sourceURL
            originalURL = attachment.originalURL
        }
    }

    private var lastReportedIdentity: Identity?

    mutating func fallbackURLToReport(for attachment: LCUIChatPreviewAttachment) -> URL? {
        let identity = Identity(attachment)
        guard lastReportedIdentity != identity,
              let fallbackURL = attachment.previewFallbackURL else { return nil }
        lastReportedIdentity = identity
        return fallbackURL
    }
}

private struct LCUIChatVideoPreviewIdentity: Hashable {
    let id: UUID
    let url: URL
}

@available(iOS 16, *)
private struct LCUIChatVideoPreview: View {
    @StateObject private var videoState = LCUIChatVideoPreviewState()

    let url: URL
    let errorTexts: LCUIChatTexts.Errors
    let onFailure: () -> Void

    var body: some View {
        Group {
            if videoState.failed {
                LCUIChatFullScreenErrorView(
                    error: LCUIChatError(title: errorTexts.defaultError, subtitle: nil)
                )
            } else {
                VideoPlayer(player: videoState.player)
                    .onAppear { videoState.start(url: url) }
                    .onDisappear { videoState.stop() }
            }
        }
        .onChange(of: videoState.failed) { failed in
            if failed { onFailure() }
        }
    }
}

@MainActor
final class LCUIChatVideoPreviewState: ObservableObject {
    @Published private(set) var player: AVPlayer?
    @Published private(set) var failed = false

    private var statusObservation: NSKeyValueObservation?
    private var playbackFailureObservation: NSObjectProtocol?

    func start(url: URL) {
        start(item: AVPlayerItem(url: url))
    }

    func start(item: AVPlayerItem) {
        guard player == nil else { return }
        let player = AVPlayer(playerItem: item)
        self.player = player
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard item.status == .failed,
                  !isAttachmentPreviewCancellation(item.error) else { return }
            Task { @MainActor [weak self, weak item] in
                guard let self, let item, self.player?.currentItem === item else { return }
                self.failed = true
            }
        }
        playbackFailureObservation = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self, weak item] notification in
            guard !isAttachmentPreviewCancellation(
                notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            ) else { return }
            Task { @MainActor [weak self, weak item] in
                guard let self, let item, self.player?.currentItem === item else { return }
                self.failed = true
            }
        }
    }

    func stop() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let playbackFailureObservation {
            NotificationCenter.default.removeObserver(playbackFailureObservation)
            self.playbackFailureObservation = nil
        }
        player?.pause()
        player = nil
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
