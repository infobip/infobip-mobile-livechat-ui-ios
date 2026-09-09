//
//  LCUIChatConstraints.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public struct LCUIChatConstraints: Sendable {
    public private(set) var maximumCharacterCount: UInt
    public private(set) var charCounterVisibleThreshold: UInt
    public private(set) var allowedContentTypes: [UTType]
    public private(set) var isAttachmentUploadEnabled: Bool
    public private(set) var maximumAttachmentByteCount: Int

    public static let defaultMaximumAttachmentByteCount = 25 * 1024 * 1024

    public init(
        maximumCharacterCount: UInt = 1024 * 4,
        charCounterVisibleThreshold: UInt = 4000,
        allowedContentTypes: [UTType] = [],
        isAttachmentUploadEnabled: Bool = true,
        maximumAttachmentByteCount: Int = LCUIChatConstraints.defaultMaximumAttachmentByteCount
    ) {
        self.maximumCharacterCount = maximumCharacterCount
        self.charCounterVisibleThreshold = charCounterVisibleThreshold
        self.allowedContentTypes = allowedContentTypes
        self.isAttachmentUploadEnabled = isAttachmentUploadEnabled
        self.maximumAttachmentByteCount = maximumAttachmentByteCount
    }

    public init(
        maximumCharacterCount: UInt = 1024 * 4,
        charCounterVisibleThreshold: UInt = 4000,
        allowedFileExtensions: [String],
        isAttachmentUploadEnabled: Bool = true,
        maximumAttachmentByteCount: Int = LCUIChatConstraints.defaultMaximumAttachmentByteCount
    ) {
        var resolved: [UTType] = []
        var unresolved: [String] = []
        for fileExtension in allowedFileExtensions {
            let normalised = fileExtension
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                .lowercased()
            if let type = UTType(filenameExtension: normalised), type.isDeclared {
                resolved.append(type)
            } else {
                unresolved.append(fileExtension)
            }
        }
        self.init(
            maximumCharacterCount: maximumCharacterCount,
            charCounterVisibleThreshold: charCounterVisibleThreshold,
            allowedContentTypes: resolved,
            isAttachmentUploadEnabled: isAttachmentUploadEnabled,
            maximumAttachmentByteCount: maximumAttachmentByteCount
        )
    }

    private var isUnrestricted: Bool { allowedContentTypes.isEmpty }

    public var allowsImageContent: Bool {
        isUnrestricted || allowedContentTypes.contains { $0.conforms(to: .image) }
    }

    public var allowsVideoContent: Bool {
        isUnrestricted || allowedContentTypes.contains { $0.conforms(to: .movie) || $0.conforms(to: .video) }
    }

    public var allowsCameraCapture: Bool {
        allowsImageContent || allowsVideoContent
    }

    public var photoLibraryFilter: PHPickerFilter? {
        switch (allowsImageContent, allowsVideoContent) {
        case (true, true): return .any(of: [.images, .videos])
        case (true, false): return .images
        case (false, true): return .videos
        case (false, false): return nil
        }
    }

    public var documentPickerContentTypes: [UTType] {
        isUnrestricted ? [.item] : allowedContentTypes
    }
}
