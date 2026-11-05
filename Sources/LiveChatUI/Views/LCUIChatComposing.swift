//
//  LCUIChatComposing.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

@available(iOS 16, *)
public struct LCUIChatComposerConfiguration {
    public private(set) var isEnabled: Bool
    public private(set) var text: Binding<String>?
    public private(set) var attachment: Binding<LCUIChatAttachment?>?
    public private(set) var onSend: (String) -> Void
    public private(set) var onSendAttachment: ((String, LCUIChatAttachment) -> Void)?
    public private(set) var onAttachmentTapped: () -> Void
    public private(set) var onTextChange: (String) -> Void

    public init(
        isEnabled: Bool = true,
        text: Binding<String>? = nil,
        attachment: Binding<LCUIChatAttachment?>? = nil,
        onSend: @escaping (String) -> Void,
        onSendAttachment: ((String, LCUIChatAttachment) -> Void)? = nil,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self.isEnabled = isEnabled
        self.text = text
        self.attachment = attachment
        self.onSend = onSend
        self.onSendAttachment = onSendAttachment
        self.onAttachmentTapped = onAttachmentTapped
        self.onTextChange = onTextChange
    }
}

@available(iOS 16, *)
@MainActor
public protocol LCUIChatComposing: View {
    init(configuration: LCUIChatComposerConfiguration)
}
