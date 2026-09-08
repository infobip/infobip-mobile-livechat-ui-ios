//
//  LCUIChatDataTypes.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// The kind of file an attachment represents, used to pick a preview strategy.
public enum LCUIChatAttachmentKind: Equatable, Sendable {
    case image
    case video
    case document

    /// Classifies a content type, so callers never have to maintain their own extension lists.
    public init(contentType: UTType) {
        if contentType.conforms(to: .image) {
            self = .image
        } else if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
            self = .video
        } else {
            self = .document
        }
    }
}

/// A locally-picked attachment (camera/photo library/document) ready to hand to the host for upload.
///
/// The payload is referenced by `fileURL` rather than held in memory, as memiry optimisation.
public struct LCUIChatAttachment: Identifiable, Sendable {
    public let id: UUID
    public let fileName: String
    public let fileURL: URL
    public let byteCount: Int
    public let contentType: UTType
    public let kind: LCUIChatAttachmentKind

    public init(
        id: UUID = UUID(),
        fileName: String,
        fileURL: URL,
        byteCount: Int,
        contentType: UTType,
        kind: LCUIChatAttachmentKind
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.byteCount = byteCount
        self.contentType = contentType
        self.kind = kind
    }

    public func loadData() throws -> Data {
        try Data(contentsOf: fileURL, options: .mappedIfSafe)
    }

    public func discard() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    public static func discardAll() {
        LCUIChatAttachmentStore.removeAll()
    }
}

extension LCUIChatAttachment: Equatable {
    public static func == (lhs: LCUIChatAttachment, rhs: LCUIChatAttachment) -> Bool {
        lhs.id == rhs.id
    }
}

public enum LCUIChatAttachmentError: Error, Equatable, Sendable {
    /// The file is larger than `LCUIChatConstraints.maximumAttachmentByteCount`.
    case tooLarge(byteCount: Int, maximum: Int)
    /// The file could not be read or copied — most often a File Provider denying access.
    case unreadable
    /// The picked item's type is not in `LCUIChatConstraints.allowedContentTypes`.
    case unsupportedType(UTType?)
    /// Camera access has been denied or restricted; the user must change it in Settings.
    ///
    /// `LCUIChatAttachmentPickerView` presents this itself, with a link to Settings, rather than
    /// reporting it through `onError`. The case exists for hosts driving their own picker.
    case cameraPermissionDenied

    /// Maps to one of the host-supplied strings, so the caller can present it without a switch.
    public func message(using texts: LCUIChatTexts.Attachments) -> Text {
        switch self {
        case .tooLarge:
            return texts.maximumAllowedSizeError
        case .cameraPermissionDenied:
            return texts.toGivePermission
        case .unreadable, .unsupportedType:
            return texts.uploadError
        }
    }
}

public struct LCUIChatPreviewAttachment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileName: String?
    public let kind: LCUIChatAttachmentKind
    public let sourceURL: URL

    public init(id: UUID = UUID(), fileName: String?, kind: LCUIChatAttachmentKind, sourceURL: URL) {
        self.id = id
        self.fileName = fileName
        self.kind = kind
        self.sourceURL = sourceURL
    }
}

/// A user-facing chat error, already localized/formatted by the host.
public struct LCUIChatError: Equatable, Sendable {
    public let title: Text?
    public let subtitle: Text?

    public init(title: Text?, subtitle: Text?) {
        self.title = title
        self.subtitle = subtitle
    }
}
