//
//  LCUIChatTexts.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

public struct LCUIChatTexts: Sendable {
    public struct Attachments: Sendable {
        public private(set) var takePhotoOrVideo: Text
        public private(set) var photoLibrary: Text
        public private(set) var browse: Text
        public private(set) var uploadError: Text
        public private(set) var maximumAllowedSizeError: Text
        public private(set) var toGivePermission: Text
        public private(set) var goToSettings: Text
        public private(set) var share: Text
        public private(set) var attachments: Text

        public init(
            takePhotoOrVideo: Text = Text("Take Photo or Video"),
            photoLibrary: Text = Text("Photo Library"),
            browse: Text = Text("Browse"),
            uploadError: Text = Text("Attachment upload failed"),
            maximumAllowedSizeError: Text = Text("Maximum allowed size exceeded"),
            toGivePermission: Text = Text("To give permissions go to Settings"),
            goToSettings: Text = Text("Settings"),
            share: Text = Text("Share"),
            attachments: Text = Text("Attachments"),
        ) {
            self.takePhotoOrVideo = takePhotoOrVideo
            self.photoLibrary = photoLibrary
            self.browse = browse
            self.uploadError = uploadError
            self.maximumAllowedSizeError = maximumAllowedSizeError
            self.toGivePermission = toGivePermission
            self.goToSettings = goToSettings
            self.share = share
            self.attachments = attachments
        }
    }

    public struct Errors: Sendable {
        public private(set) var defaultError: Text
        public private(set) var apiErrorFormatted: String // Interpolated with the error code, cannot be Text
        public private(set) var noInternetError: Text
        public private(set) var noConnection: Text

        public init(
            defaultError: Text = Text("Something went wrong."),
            apiErrorFormatted: String = "Try again later or contact customer support. Error code: %1$@.",
            noInternetError: Text = Text("No Internet connection"),
            noConnection: Text = Text("No connection")
        ) {
            self.defaultError = defaultError
            self.apiErrorFormatted = apiErrorFormatted
            self.noInternetError = noInternetError
            self.noConnection = noConnection
        }
    }

    public private(set) var attachments: Attachments
    public private(set) var errors: Errors
    public private(set) var navigationTitle: Text
    public private(set) var sendAMessage: String // Used as placeholer in a textfield, cannot be Text
    public private(set) var cancel: Text
    public private(set) var back: Text

    public init (
        attachments: Attachments = Attachments(),
        errors: Errors = Errors(),
        navigationTitle: Text = Text("Chat"),
        sendAMessage: String = "Send a message...",
        cancel: Text = Text("Cancel"),
        back: Text = Text("Back")
    ) {
            self.attachments = attachments
            self.errors = errors
            self.navigationTitle = navigationTitle
            self.sendAMessage = sendAMessage
            self.cancel = cancel
            self.back = back
    }
}
