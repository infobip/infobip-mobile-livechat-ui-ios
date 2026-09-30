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
    // The synthesized `Bundle.module` symbol only exists once SPM's build planning
    // generates `resource_bundle_accessor.swift`.
    static let resourceBundle: Bundle = {
        let bundleName = "infobip-mobile-livechat-ui-ios_LiveChatUI.bundle"
        let candidateURLs = [
            Bundle.main.resourceURL,
            Bundle(for: LCUIChatBundleToken.self).resourceURL,
            Bundle.main.bundleURL
        ]
        for case let url? in candidateURLs {
            let bundleURL = url.appendingPathComponent(bundleName)
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        return Bundle(for: LCUIChatBundleToken.self)
    }()

    public static func bundledImage(named name: String, fallback: Image) -> Image {
        guard UIImage(named: name, in: resourceBundle, compatibleWith: nil) != nil else {
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
