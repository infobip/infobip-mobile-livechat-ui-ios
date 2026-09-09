//
//  LCUIChatAttachmentStore.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import Foundation
import AVFoundation
import CoreTransferable
import UIKit
import UniformTypeIdentifiers

/// Package-owned staging area for picked attachments.
///
/// Everything the user picks is copied here so the host gets a plain, non-security-scoped file URL
/// with a stable lifetime, and so the payload never has to be held in memory.
enum LCUIChatAttachmentStore {
    private static let directoryName = "com.infobip.livechatui.attachments"
    private static let maximumFileNameLength = 128

    /// Fixed locale/calendar/time zone: the user's own would render `yyyy` as a Buddhist or Persian
    /// year, producing filenames that neither sort nor round-trip. Static, so it is built once.
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    static func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A unique destination that still carries the sanitised name, so nothing ever collides.
    static func destination(fileName: String) throws -> URL {
        try directory().appendingPathComponent("\(UUID().uuidString)-\(fileName)", isDirectory: false)
    }

    static func removeAll() {
        guard let url = try? directory() else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Takes ownership of a file whose URL is about to become invalid.
    /// `UIImagePickerController` hands its camera recording over as a temp file it deletes on dismissal.
    static func claim(_ source: URL) throws -> URL {
        let destination = try destination(fileName: source.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: source, to: destination)
        } catch {
            try FileManager.default.copyItem(at: source, to: destination)
        }
        return destination
    }

    static func byteCount(of url: URL) -> Int? {
        try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
    }

    static func contentType(of url: URL) -> UTType? {
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return type
        }
        return UTType(filenameExtension: url.pathExtension)
    }

    /// Produces a name that is safe to put in a `Content-Disposition` header.
    ///
    /// A picked file's name is attacker-influenced (a shared document can be called anything). The
    /// raw value may contain quotes, CR/LF or control characters — the classic ingredients of
    /// header injection — so this whitelists rather than blacklists, and guarantees a non-empty
    /// result with a plausible extension.
    static func sanitizedFileName(_ proposed: String?, contentType: UTType?) -> String {
        let fallbackExtension = contentType?.preferredFilenameExtension
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " .-_"))

        var cleaned = String(
            (proposed ?? "").unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        )
        // Collapse runs of dots so no ".." survives, then strip leading/trailing dots and spaces —
        // a name of "." or ".." would otherwise resolve to a directory.
        while cleaned.contains("..") {
            cleaned = cleaned.replacingOccurrences(of: "..", with: ".")
        }
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: " ."))

        if cleaned.isEmpty {
            let stem = "\(timestampFormatter.string(from: Date()))"
            return fallbackExtension.map { "\(stem).\($0)" } ?? stem
        }

        if cleaned.count > maximumFileNameLength {
            let url = URL(fileURLWithPath: cleaned)
            let fileExtension = url.pathExtension
            let stem = url.deletingPathExtension().lastPathComponent
            let room = max(1, maximumFileNameLength - (fileExtension.isEmpty ? 0 : fileExtension.count + 1))
            let truncated = String(stem.prefix(room))
            cleaned = fileExtension.isEmpty ? truncated : "\(truncated).\(fileExtension)"
        }

        // Give extension-less files one, so receivers can infer the type.
        if URL(fileURLWithPath: cleaned).pathExtension.isEmpty, let fallbackExtension {
            cleaned = "\(cleaned).\(fallbackExtension)"
        }
        return cleaned
    }

    /// A timestamped name for content that arrives without one (camera captures, library assets).
    static func generatedFileName(contentType: UTType?) -> String {
        sanitizedFileName(nil, contentType: contentType)
    }
}

/// Moves picked files into `LCUIChatAttachmentStore` off the main actor.
actor LCUIChatAttachmentImporter {
    /// Quality 1.0 produces ~8 MB for a 12 MP capture with no perceptible benefit over 0.9.
    private static let photoCompressionQuality: CGFloat = 0.9

    /// Copies a file the picker handed us into package storage.
    ///
    /// - Parameter isSecurityScoped: `true` for URLs from `.fileImporter`. Without the
    ///   start/stop bracket, reading anything backed by a File Provider (iCloud Drive, Dropbox)
    ///   fails outright.
    func stage(
        source: URL,
        isSecurityScoped: Bool,
        preferredFileName: String? = nil,
        allowedContentTypes: [UTType],
        maximumByteCount: Int
    ) async throws -> LCUIChatAttachment {
        let staged = try copyIntoStore(source: source, isSecurityScoped: isSecurityScoped, maximumByteCount: maximumByteCount)
        return try await finish(
            stagedFile: staged,
            preferredFileName: preferredFileName ?? source.lastPathComponent,
            allowedContentTypes: allowedContentTypes,
            maximumByteCount: maximumByteCount
        )
    }

    private func copyIntoStore(source: URL, isSecurityScoped: Bool, maximumByteCount: Int) throws -> URL {
        var didAccess = false
        if isSecurityScoped {
            // Returns false both for failure and for URLs that need no scoping, so its result only
            // tells us whether a matching `stop` is owed — never whether the read will succeed.
            didAccess = source.startAccessingSecurityScopedResource()
        }
        defer {
            if didAccess {
                source.stopAccessingSecurityScopedResource()
            }
        }

        // Checked before the copy: rejecting a 500 MB video should not first duplicate it.
        guard let byteCount = LCUIChatAttachmentStore.byteCount(of: source) else {
            throw LCUIChatAttachmentError.unreadable()
        }
        guard byteCount <= maximumByteCount else {
            throw LCUIChatAttachmentError.tooLarge(byteCount: byteCount, maximum: maximumByteCount)
        }

        let destination = try LCUIChatAttachmentStore.destination(fileName: source.lastPathComponent)
        do {
            // Kernel-level copy: streams, so peak memory stays flat regardless of file size.
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            throw LCUIChatAttachmentError.unreadable(underlyingError: error.localizedDescription)
        }
        return destination
    }

    /// Encodes and writes a camera photo (`UIImagePickerController` yields a `UIImage)` — there is no file URL to copy, yet
    func stage(photo: UIImage, maximumByteCount: Int) throws -> LCUIChatAttachment {
        guard let data = photo.jpegData(compressionQuality: Self.photoCompressionQuality) else {
            throw LCUIChatAttachmentError.unreadable()
        }
        guard data.count <= maximumByteCount else {
            throw LCUIChatAttachmentError.tooLarge(byteCount: data.count, maximum: maximumByteCount)
        }

        let fileName = LCUIChatAttachmentStore.generatedFileName(contentType: .jpeg)
        let destination = try LCUIChatAttachmentStore.destination(fileName: fileName)
        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            throw LCUIChatAttachmentError.unreadable(underlyingError: error.localizedDescription)
        }

        return LCUIChatAttachment(
            fileName: fileName,
            fileURL: destination,
            byteCount: data.count,
            contentType: .jpeg,
            kind: .image
        )
    }

    /// This method owns `stagedFile` and deletes it on every failure.
    func finish(
        stagedFile: URL,
        preferredFileName: String?,
        allowedContentTypes: [UTType],
        maximumByteCount: Int
    ) async throws -> LCUIChatAttachment {
        var fileURL = stagedFile
        var contentType = LCUIChatAttachmentStore.contentType(of: fileURL)
        var proposedName = preferredFileName

        do {
            if let remuxed = try await remuxedMovie(at: fileURL, contentType: contentType, allowedContentTypes: allowedContentTypes) {
                try? FileManager.default.removeItem(at: fileURL)
                fileURL = remuxed.url
                contentType = remuxed.contentType
                proposedName = proposedName.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
            } else {
                try validate(contentType: contentType, against: allowedContentTypes)
            }
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            throw error
        }

        guard let byteCount = LCUIChatAttachmentStore.byteCount(of: fileURL) else {
            try? FileManager.default.removeItem(at: fileURL)
            throw LCUIChatAttachmentError.unreadable()
        }
        guard byteCount <= maximumByteCount else {
            try? FileManager.default.removeItem(at: fileURL)
            throw LCUIChatAttachmentError.tooLarge(byteCount: byteCount, maximum: maximumByteCount)
        }

        let resolvedType = contentType ?? .data
        return LCUIChatAttachment(
            fileName: LCUIChatAttachmentStore.sanitizedFileName(
                proposedName ?? fileURL.lastPathComponent,
                contentType: resolvedType
            ),
            fileURL: fileURL,
            byteCount: byteCount,
            contentType: resolvedType,
            kind: LCUIChatAttachmentKind(contentType: resolvedType)
        )
    }

    /// Rewrites a movie into an allowed container when its own is not on the list.
    /// A camera capture is always QuickTime, and `quickTimeMovie` does not conform to `mpeg4Movie`
    private func remuxedMovie(
        at source: URL,
        contentType: UTType?,
        allowedContentTypes: [UTType]
    ) async throws -> (url: URL, contentType: UTType)? {
        guard !allowedContentTypes.isEmpty,
              let contentType,
              contentType.conforms(to: .movie),
              !allowedContentTypes.contains(where: { contentType.conforms(to: $0) })
        else { return nil }

        let candidates = allowedContentTypes.filter { $0.conforms(to: .movie) }
        guard !candidates.isEmpty else { return nil }

        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            return nil
        }
        let compatible = await session.compatibleFileTypes()
        guard let target = candidates.first(where: { compatible.contains(AVFileType($0.identifier)) }),
              let fileExtension = target.preferredFilenameExtension
        else { return nil }

        let destination = try LCUIChatAttachmentStore.destination(
            fileName: source.deletingPathExtension().lastPathComponent + "." + fileExtension
        )
        session.outputURL = destination
        session.outputFileType = AVFileType(target.identifier)
        await session.export()

        guard session.status == .completed else {
            try? FileManager.default.removeItem(at: destination)
            throw LCUIChatAttachmentError.unsupportedType(contentType, underlyingError: session.error?.localizedDescription)
        }
        return (destination, target)
    }

    private func validate(contentType: UTType?, against allowed: [UTType]) throws {
        guard !allowed.isEmpty else { return }
        guard let contentType else {
            throw LCUIChatAttachmentError.unsupportedType(nil)
        }
        guard allowed.contains(where: { contentType.conforms(to: $0) }) else {
            throw LCUIChatAttachmentError.unsupportedType(contentType)
        }
    }
}

private extension AVAssetExportSession {
    /// `determineCompatibleFileTypes` and `exportAsynchronously` are required for iOS older than 18
    func compatibleFileTypes() async -> [AVFileType] {
        await withCheckedContinuation { continuation in
            determineCompatibleFileTypes { continuation.resume(returning: $0) }
        }
    }

    func export() async {
        await withCheckedContinuation { continuation in
            exportAsynchronously { continuation.resume() }
        }
    }
}

/// Carries a photo-library item to disk without its bytes passing through RAM for huge video files.
@available(iOS 16, *)
struct LCUIChatTransferredFile: Transferable {
    let url: URL
    /// Kept alongside the URL because the staged copy is named `UUID()-<name>`
    let originalName: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try Self.ingest(received.file)
        }
        FileRepresentation(importedContentType: .movie) { received in
            try Self.ingest(received.file)
        }
    }

    /// The received URL is valid only for the duration of the importing closure, so we copy it now.
    private static func ingest(_ received: URL) throws -> LCUIChatTransferredFile {
        let fileName = LCUIChatAttachmentStore.sanitizedFileName(
            received.lastPathComponent,
            contentType: LCUIChatAttachmentStore.contentType(of: received)
        )
        let destination = try LCUIChatAttachmentStore.destination(fileName: fileName)
        try FileManager.default.copyItem(at: received, to: destination)
        return LCUIChatTransferredFile(url: destination, originalName: fileName)
    }
}
