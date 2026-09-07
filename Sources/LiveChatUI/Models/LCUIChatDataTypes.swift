//
//  LCUIChatDataTypes.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import Foundation
import SwiftUI

/// The kind of file an attachment represents, used to pick a preview strategy.
public enum LCUIChatAttachmentKind: Equatable, Sendable {
    case image
    case video
    case document
}

/// A locally-picked attachment (camera/photo library/document) ready to hand to the host for upload.
public struct LCUIChatAttachment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileName: String?
    public let data: Data
    public let kind: LCUIChatAttachmentKind

    public init(id: UUID = UUID(), fileName: String?, data: Data, kind: LCUIChatAttachmentKind) {
        self.id = id
        self.fileName = fileName
        self.data = data
        self.kind = kind
    }
}

/// An attachment received from the widget/thread, to be shown in `LCUIChatAttachmentPreview`.
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
