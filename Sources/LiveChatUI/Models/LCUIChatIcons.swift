//
//  LCUIChatIcons.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import UIKit

public struct LCUIChatIcons: Sendable {
    public private(set) var attachmentsCamera: Image
    public private(set) var attachmentsGallery: Image
    public private(set) var attachmentsDocuments: Image
    public private(set) var attachmentSharing: Image
    public private(set) var closingNavigation: Image
    public private(set) var backNavigation: Image
    public private(set) var addAttachmentButton: Image
    public private(set) var sendButton: Image
    public private(set) var fullScreenErrorIcon: Image

    public init (
        attachmentsCamera: Image = Image(systemName: "camera"),
        attachmentsGallery: Image = Image(systemName: "photo.on.rectangle"),
        attachmentsDocuments: Image = Image(systemName: "folder"),
        attachmentSharing: Image = Image(systemName: "square.and.arrow.up"),
        closingNavigation: Image = Image(systemName: "xmark"),
        backNavigation: Image = Image(systemName: "chevron.backward"),
        addAttachmentButton: Image = Image(systemName: "paperclip"),
        sendButton: Image = Image(systemName: "paperplane.fill"),
        fullScreenErrorIcon: Image = Image(systemName: "exclamationmark.circle")
       ) {
           // Forced to rendering mode `.template` in order to be able to tint so supplied icons (ie SVG/PDF), even though default SF Symbols do not need it (they are alwayas in `.template` mode).
           self.attachmentsCamera = attachmentsCamera.renderingMode(.template)
           self.attachmentsGallery = attachmentsGallery.renderingMode(.template)
           self.attachmentsDocuments = attachmentsDocuments.renderingMode(.template)
           self.attachmentSharing = attachmentSharing.renderingMode(.template)
           self.closingNavigation = closingNavigation.renderingMode(.template)
           self.backNavigation = backNavigation.renderingMode(.template)
           self.addAttachmentButton = addAttachmentButton.renderingMode(.template)
           self.sendButton = sendButton.renderingMode(.template)
           self.fullScreenErrorIcon = fullScreenErrorIcon.renderingMode(.template)
    }
}
