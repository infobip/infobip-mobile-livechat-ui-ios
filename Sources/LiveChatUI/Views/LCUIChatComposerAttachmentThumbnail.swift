//
//  LCUIChatComposerAttachmentThumbnail.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import AVFoundation
import ImageIO
import SwiftUI

@available(iOS 16, *)
public struct LCUIChatComposerAttachmentThumbnail: View {
    @Environment(\.lcuiChatSettings) private var settings
    @State private var thumbnail: UIImage?

    private var colors: LCUIChatTheme.Colors { settings.theme.colors }
    private var thumbnailStyle: LCUIChatTheme.AttachmentThumbnail { settings.theme.attachmentThumbnail }

    private let attachment: LCUIChatAttachment
    private let onRemove: () -> Void

    public init(attachment: LCUIChatAttachment, onRemove: @escaping () -> Void) {
        self.attachment = attachment
        self.onRemove = onRemove
    }

    private let size: CGFloat = 96
    private let cornerRadius: CGFloat = 12

    public var body: some View {
        ZStack {
            switch attachment.kind {
            case .image, .video:
                mediaThumbnail
            case .document:
                documentThumbnail
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                settings.icons.removeAttachment
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(thumbnailStyle.removeButtonForegroundColor)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(thumbnailStyle.removeButtonBackgroundColor))
                    .frame(width: 33, height: 33)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.texts.attachments.removeAttachment)
        }
        .task(id: attachment.id) {
            thumbnail = nil
            guard attachment.kind != .document else { return }
            let data = await LCUIChatComposerThumbnailLoader.shared.data(for: attachment)
            guard !Task.isCancelled else { return }
            thumbnail = data.flatMap(UIImage.init(data:))
        }
    }

    private var mediaThumbnail: some View {
        ZStack {
            Rectangle().fill(colors.secondary.opacity(0.15))
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                (attachment.kind == .image
                    ? settings.icons.imageThumbnailPlaceholder
                    : settings.icons.videoThumbnailPlaceholder)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(colors.secondary)
            }
            if attachment.kind == .video {
                settings.icons.videoPlayOverlay
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(thumbnailStyle.videoPlayColor)
                    .shadow(color: thumbnailStyle.videoPlayShadowColor, radius: 2)
            }
        }
    }

    private var documentThumbnail: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 0)
            settings.icons.documentThumbnail
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(colors.primary)
            Text(attachment.fileName)
                .font(thumbnailStyle.fileNameFont)
                .foregroundStyle(colors.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
            Spacer(minLength: 0)
        }
        .frame(width: size, height: size)
        .background(colors.background)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(colors.secondary.opacity(0.3), lineWidth: 1)
        }
    }
}

/// Produces small bitmap data off the main actor, so large picked files do not block typing.
private actor LCUIChatComposerThumbnailLoader {
    static let shared = LCUIChatComposerThumbnailLoader()

    func data(for attachment: LCUIChatAttachment) -> Data? {
        guard !Task.isCancelled else { return nil }
        switch attachment.kind {
        case .image:
            guard let source = CGImageSourceCreateWithURL(attachment.fileURL as CFURL, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 288
                  ] as CFDictionary) else { return nil }
            return UIImage(cgImage: image).jpegData(compressionQuality: 0.85)
        case .video:
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: attachment.fileURL))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 288, height: 288)
            guard let image = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
            return UIImage(cgImage: image).jpegData(compressionQuality: 0.85)
        case .document:
            return nil
        }
    }
}
