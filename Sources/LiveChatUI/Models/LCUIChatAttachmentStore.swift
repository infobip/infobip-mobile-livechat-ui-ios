//
//  LCUIChatAttachmentStore.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import Foundation
import CoreTransferable
import UIKit
import UniformTypeIdentifiers
import os

/// Package-owned staging area for picked attachments.
///
/// Everything the user picks is copied here so the host gets a plain, non-security-scoped file URL
/// with a stable lifetime, and so the payload never has to be held in memory.
enum LCUIChatAttachmentStore {
    private static let directoryName = "com.infobip.livechatui.attachments"
    private static let maximumFileNameLength = 128

    static let logger = Logger(subsystem: "com.infobip.livechatui", category: "attachments")

    /// Fixed locale/calendar/time zone: the user's own would render `yyyy` as a Buddhist or Persian
    /// year, producing filenames that neither sort nor round-trip. Static, so it is built once.
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
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
            let stem = "attachment-\(timestampFormatter.string(from: Date()))"
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
///
/// This is an `actor` rather than a set of `nonisolated` functions on purpose: it makes it
/// impossible to accidentally perform the copy — or a JPEG encode — on the main thread, which is
/// what the previous `Data(contentsOf:)` calls in the picker were doing.
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
    ) throws -> LCUIChatAttachment {
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

        let contentType = LCUIChatAttachmentStore.contentType(of: source)
        try validate(contentType: contentType, against: allowedContentTypes)

        // Checked before the copy: rejecting a 500 MB video should not first duplicate it.
        guard let byteCount = LCUIChatAttachmentStore.byteCount(of: source) else {
            throw LCUIChatAttachmentError.unreadable
        }
        guard byteCount <= maximumByteCount else {
            throw LCUIChatAttachmentError.tooLarge(byteCount: byteCount, maximum: maximumByteCount)
        }

        let fileName = LCUIChatAttachmentStore.sanitizedFileName(
            preferredFileName ?? source.lastPathComponent,
            contentType: contentType
        )
        let destination = try LCUIChatAttachmentStore.destination(fileName: fileName)
        do {
            // Kernel-level copy: streams, so peak memory stays flat regardless of file size.
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            LCUIChatAttachmentStore.logger.error("Failed to stage attachment: \(error.localizedDescription, privacy: .public)")
            throw LCUIChatAttachmentError.unreadable
        }

        let resolvedType = contentType ?? .data
        return LCUIChatAttachment(
            fileName: fileName,
            fileURL: destination,
            byteCount: byteCount,
            contentType: resolvedType,
            kind: LCUIChatAttachmentKind(contentType: resolvedType)
        )
    }

    /// Encodes and writes a camera photo. `UIImagePickerController` yields a `UIImage` for stills —
    /// there is no file URL to copy — so this is the one path that must serialise through memory.
    func stage(photo: UIImage, maximumByteCount: Int) throws -> LCUIChatAttachment {
        guard let data = photo.jpegData(compressionQuality: Self.photoCompressionQuality) else {
            throw LCUIChatAttachmentError.unreadable
        }
        guard data.count <= maximumByteCount else {
            throw LCUIChatAttachmentError.tooLarge(byteCount: data.count, maximum: maximumByteCount)
        }

        let fileName = LCUIChatAttachmentStore.generatedFileName(contentType: .jpeg)
        let destination = try LCUIChatAttachmentStore.destination(fileName: fileName)
        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            LCUIChatAttachmentStore.logger.error("Failed to stage photo: \(error.localizedDescription, privacy: .public)")
            throw LCUIChatAttachmentError.unreadable
        }

        return LCUIChatAttachment(
            fileName: fileName,
            fileURL: destination,
            byteCount: data.count,
            contentType: .jpeg,
            kind: .image
        )
    }

    /// Validates a file already written into package storage by `LCUIChatTransferredFile`.
    ///
    /// `Transferable`'s `FileRepresentation` hands over a URL that is deleted as soon as the
    /// importing closure returns, so the copy has to happen there — before the limit can be
    /// applied. The check is therefore after the fact, and an oversized file is deleted here. The
    /// cost is disk, never memory, which is the trade this whole type exists to make.
    func adopt(
        stagedFile: URL,
        preferredFileName: String?,
        maximumByteCount: Int
    ) throws -> LCUIChatAttachment {
        let contentType = LCUIChatAttachmentStore.contentType(of: stagedFile) ?? .data
        guard let byteCount = LCUIChatAttachmentStore.byteCount(of: stagedFile) else {
            try? FileManager.default.removeItem(at: stagedFile)
            throw LCUIChatAttachmentError.unreadable
        }
        guard byteCount <= maximumByteCount else {
            try? FileManager.default.removeItem(at: stagedFile)
            throw LCUIChatAttachmentError.tooLarge(byteCount: byteCount, maximum: maximumByteCount)
        }

        return LCUIChatAttachment(
            fileName: LCUIChatAttachmentStore.sanitizedFileName(
                preferredFileName ?? stagedFile.lastPathComponent,
                contentType: contentType
            ),
            fileURL: stagedFile,
            byteCount: byteCount,
            contentType: contentType,
            kind: LCUIChatAttachmentKind(contentType: contentType)
        )
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

/// Carries a photo-library item to disk without its bytes passing through memory.
///
/// `loadTransferable(type: Data.self)` — what the picker used to call — materialises the whole
/// asset as `Data`. A `FileRepresentation` instead gives us a URL we can copy, so a 400 MB video
/// costs disk rather than RAM.
@available(iOS 16, *)
struct LCUIChatTransferredFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            LCUIChatTransferredFile(url: try Self.ingest(received.file))
        }
        FileRepresentation(importedContentType: .movie) { received in
            LCUIChatTransferredFile(url: try Self.ingest(received.file))
        }
    }

    /// The received URL is valid only for the duration of the importing closure, so copy it now.
    private static func ingest(_ received: URL) throws -> URL {
        let fileName = LCUIChatAttachmentStore.sanitizedFileName(
            received.lastPathComponent,
            contentType: LCUIChatAttachmentStore.contentType(of: received)
        )
        let destination = try LCUIChatAttachmentStore.destination(fileName: fileName)
        try FileManager.default.copyItem(at: received, to: destination)
        return destination
    }
}
