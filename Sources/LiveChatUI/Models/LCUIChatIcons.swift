//
//  LCUIChatIcons.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import UIKit

private final class LCUIChatBundleToken {}

extension LCUIChatIcons {
    static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else // To remove after cocoapods is no more
        let podBundle = Bundle(for: LCUIChatBundleToken.self)
        if let resourceBundleURL = podBundle.url(forResource: "LiveChatUI", withExtension: "bundle"),
           let resourceBundle = Bundle(url: resourceBundleURL) {
            return resourceBundle
        }
        return podBundle
        #endif
    }()

    public static func bundledImage(named name: String, fallback: Image) -> Image {
        guard UIImage(named: name, in: resourceBundle, compatibleWith: nil) != nil else {
            assertionFailure("LiveChatUI: could not find image \"\(name)\" in \(resourceBundle); falling back to a system symbol.")
            return fallback
        }
        return Image(name, bundle: resourceBundle)
    }
}

public struct LCUIChatIcons: Sendable {
    public struct Attachments: Sendable {
        public private(set) var camera: Image
        public private(set) var gallery: Image
        public private(set) var documents: Image
        public private(set) var sharing: Image
        public private(set) var addButton: Image

        public init(
            camera: Image = Image(systemName: "camera"),
            gallery: Image = Image(systemName: "photo.on.rectangle"),
            documents: Image = Image(systemName: "folder"),
            sharing: Image = Image(systemName: "square.and.arrow.up"),
            addButton: Image = Image(systemName: "paperclip")
        ) {
            // Forced to rendering mode `.template` in order to be able to tint so supplied icons (ie SVG/PDF), even though default SF Symbols do not need it (they are alwayas in `.template` mode).
            self.camera = camera.renderingMode(.template)
            self.gallery = gallery.renderingMode(.template)
            self.documents = documents.renderingMode(.template)
            self.sharing = sharing.renderingMode(.template)
            self.addButton = addButton.renderingMode(.template)
        }
    }

    public struct Navigation: Sendable {
        public private(set) var closing: Image
        public private(set) var back: Image

        public init(
            closing: Image = Image(systemName: "xmark"),
            back: Image = Image(systemName: "chevron.backward")
        ) {
            self.closing = closing.renderingMode(.template)
            self.back = back.renderingMode(.template)
        }
    }

    public private(set) var attachments: Attachments
    public private(set) var navigation: Navigation
    public private(set) var sendButton: Image
    public private(set) var fullScreenErrorIcon: Image

    public init (
        attachments: Attachments = Attachments(),
        navigation: Navigation = Navigation(),
        sendButton: Image = LCUIChatIcons.bundledImage(named: "SendButtonIcon", fallback: Image(systemName: "paperplane.fill")),
        fullScreenErrorIcon: Image = Image(systemName: "exclamationmark.circle")
       ) {
           self.attachments = attachments
           self.navigation = navigation
           // Forced to rendering mode `.template` in order to be able to tint so supplied icons (ie SVG/PDF), even though default SF Symbols do not need it (they are alwayas in `.template` mode).
           self.sendButton = sendButton.renderingMode(.template)
           self.fullScreenErrorIcon = fullScreenErrorIcon.renderingMode(.template)
    }
}
