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
    public private(set) var onSend: (String) -> Void
    public private(set) var onAttachmentTapped: () -> Void
    public private(set) var onTextChange: (String) -> Void

    public init(
        isEnabled: Bool = true,
        text: Binding<String>? = nil,
        onSend: @escaping (String) -> Void,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self.isEnabled = isEnabled
        self.text = text
        self.onSend = onSend
        self.onAttachmentTapped = onAttachmentTapped
        self.onTextChange = onTextChange
    }
}

@available(iOS 16, *)
@MainActor
public protocol LCUIChatComposing: View {
    init(configuration: LCUIChatComposerConfiguration)
}
