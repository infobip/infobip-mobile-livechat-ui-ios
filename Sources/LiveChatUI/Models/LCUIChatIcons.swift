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

    public init (
        attachmentsCamera: Image = Image(systemName: "camera"),
        attachmentsGallery: Image = Image(systemName: "photo.on.rectangle"),
        attachmentsDocuments: Image = Image(systemName: "folder"),
        attachmentSharing: Image = Image(systemName: "square.and.arrow.up"),
        closingNavigation: Image = Image(systemName: "xmark"),
        backNavigation: Image = Image(systemName: "chevron.backward"),
        addAttachmentButton: Image = Image(systemName: "paperclip"),
        sendButton: Image = Image(systemName: "paperplane.fill")
       ) {
           self.attachmentsCamera = attachmentsCamera
           self.attachmentsGallery = attachmentsGallery
           self.attachmentsDocuments = attachmentsDocuments
           self.attachmentSharing = attachmentSharing
           self.closingNavigation = closingNavigation
           self.backNavigation = backNavigation
           self.addAttachmentButton = addAttachmentButton
           self.sendButton = sendButton
    }
}
