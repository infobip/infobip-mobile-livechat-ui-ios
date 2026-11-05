//
//  LCUIChatComposerPreviews.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

#if DEBUG
import AVFoundation
import SwiftUI
import UIKit

// NOTE: this struct is a canvas wraper just for preview

@available(iOS 16, *)
private struct LCUIChatComposerAttachmentPreview: View {
    let kind: LCUIChatAttachmentKind
    let theme: LCUIChatTheme

    @State private var caption: String
    @State private var attachment: LCUIChatAttachment?

    init(kind: LCUIChatAttachmentKind, caption: String, dark: Bool = false) {
        self.kind = kind
        self.theme = LCUIChatTheme(
            currentColorMode: dark ? .dark : .light,
            layout: .init(prefersLiquidGlass: false)
        )
        _caption = State(initialValue: caption)
    }

    var body: some View {
        VStack {
            Spacer()
            LCUIChatComposerView(
                text: $caption,
                attachment: $attachment,
                onSend: { _ in },
                onSendAttachment: { _, picked in picked.discard() }
            )
        }
        .frame(width: 350, height: 250)
        .background(theme.colors.background)
        .lcuiChatSettings(.init(theme: theme))
        .task {
            guard let picked = await LCUIChatComposerPreviewFile.makeAttachment(kind: kind) else { return }
            guard !Task.isCancelled else {
                picked.discard()
                return
            }
            attachment = picked
        }
        .onDisappear { attachment?.discard() }
    }
}

@available(iOS 16, *)
@MainActor
enum LCUIChatComposerPreviewFile {
    static func makeAttachment(kind: LCUIChatAttachmentKind) async -> LCUIChatAttachment? {
        switch kind {
        case .image:
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            let image = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256)).image { context in
                drawScene(in: context.cgContext)
            }
            guard let data = image.pngData(),
                  (try? data.write(to: url)) != nil else { return nil }
            return LCUIChatAttachment(
                fileName: "office.png", fileURL: url, byteCount: data.count,
                contentType: .png, kind: .image
            )
        case .video:
            guard let url = await makeVideo() else { return nil }
            return LCUIChatAttachment(
                fileName: "office-tour.mov", fileURL: url,
                byteCount: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0,
                contentType: .quickTimeMovie, kind: .video
            )
        case .document:
            return LCUIChatAttachment(
                fileName: "very-long-invoice-filename.pdf",
                fileURL: FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("pdf"),
                byteCount: 0, contentType: .pdf, kind: .document
            )
        }
    }

    private static func makeVideo() async -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return nil }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 256,
            AVVideoHeightKey: 256
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        guard writer.startWriting(), let buffer = makePixelBuffer() else { return nil }
        writer.startSession(atSourceTime: .zero)
        guard input.isReadyForMoreMediaData,
              adaptor.append(buffer, withPresentationTime: .zero) else {
            writer.cancelWriting()
            return nil
        }
        input.markAsFinished()
        await withCheckedContinuation { continuation in
            writer.finishWriting { continuation.resume() }
        }
        return writer.status == .completed ? url : nil
    }

    private static func makePixelBuffer() -> CVPixelBuffer? {
        var optionalBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, 256, 256, kCVPixelFormatType_32ARGB, nil, &optionalBuffer
        )
        guard status == kCVReturnSuccess, let buffer = optionalBuffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: 256, height: 256, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }
        drawScene(in: context)
        return buffer
    }

    private static func drawScene(in context: CGContext) {
        context.setFillColor(UIColor(red: 0.72, green: 0.78, blue: 0.75, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
        context.setFillColor(UIColor(red: 0.18, green: 0.28, blue: 0.34, alpha: 1).cgColor)
        context.fill(CGRect(x: 18, y: 42, width: 105, height: 196))
        context.fill(CGRect(x: 135, y: 42, width: 103, height: 196))
        context.setFillColor(UIColor(red: 0.62, green: 0.77, blue: 0.83, alpha: 1).cgColor)
        context.fill(CGRect(x: 27, y: 51, width: 87, height: 178))
        context.fill(CGRect(x: 144, y: 51, width: 85, height: 178))
        context.setFillColor(UIColor(red: 0.35, green: 0.41, blue: 0.40, alpha: 1).cgColor)
        context.fill(CGRect(x: 18, y: 130, width: 220, height: 8))
        context.setFillColor(UIColor(red: 0.69, green: 0.42, blue: 0.29, alpha: 1).cgColor)
        context.fill(CGRect(x: 72, y: 10, width: 125, height: 56))
    }
}

@available(iOS 16, *)
#Preview("Composer · photo and caption") {
    LCUIChatComposerAttachmentPreview(kind: .image, caption: "Here is a photo of our office.")
}

@available(iOS 16, *)
#Preview("Composer · photo without caption") {
    LCUIChatComposerAttachmentPreview(kind: .image, caption: "")
}

@available(iOS 16, *)
#Preview("Composer · video and caption") {
    LCUIChatComposerAttachmentPreview(kind: .video, caption: "Here is a screen recording.")
}

@available(iOS 16, *)
#Preview("Composer · document and caption") {
    LCUIChatComposerAttachmentPreview(kind: .document, caption: "Please check the invoice.")
}

@available(iOS 16, *)
#Preview("Composer · document in dark mode") {
    LCUIChatComposerAttachmentPreview(kind: .document, caption: "Please check the invoice.", dark: true)
}
#endif
