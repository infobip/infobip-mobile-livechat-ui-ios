//
//  LCUIChatTexts.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

public struct LCUIChatTexts: Sendable {
    public private(set) var navigationTitle: Text
    public private(set) var noConnection: Text
    public private(set) var takePhotoOrVideo: Text
    public private(set) var photoLibrary: Text
    public private(set) var browse: Text
    public private(set) var settings: Text
    public private(set) var attachmentUploadError: Text
    public private(set) var maximumAllowedSizeError: Text
    public private(set) var toGivePermission: Text
    public private(set) var defaultError: Text
    public private(set) var apiErrorFormatted: String // Interpolated with the error code, cannot be Text
    public private(set) var noInternetError: Text
    public private(set) var sendAMessage: String // Used as placeholer in a textfield, cannot be Text
    
    public init (
        navigationTitle: Text = Text("Chat"),
        noConnection: Text = Text("No connection"),
        sendAMessage: String = "Send a message...",
        takePhotoOrVideo: Text = Text("Take Photo or Video"),
        photoLibrary: Text = Text("Photo Library"),
        browse: Text = Text("Browse"),
        settings: Text = Text("Settings"),
        attachmentUploadError: Text = Text("Attachment upload failed"),
        maximumAllowedSizeError: Text = Text("Maximum allowed size exceeded"),
        toGivePermission: Text = Text("To give permissions go to Settings"),
        defaultError: Text = Text("Something went wrong."),
        apiErrorFormatted: String = "Try again later or contact customer support. Error code: %1$@.",
        noInternetError: Text = Text("No Internet connection")
    ) {
            self.navigationTitle = navigationTitle
            self.noConnection = noConnection
            self.sendAMessage = sendAMessage
            self.takePhotoOrVideo = takePhotoOrVideo
            self.photoLibrary = photoLibrary
            self.browse = browse
            self.settings = settings
            self.attachmentUploadError = attachmentUploadError
            self.maximumAllowedSizeError = maximumAllowedSizeError
            self.toGivePermission = toGivePermission
            self.defaultError = defaultError
            self.apiErrorFormatted = apiErrorFormatted
            self.noInternetError = noInternetError
    }
}
