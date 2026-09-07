//
//  LCUIChatErrorBannerView.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

@available(iOS 16, *)
public struct LCUIChatErrorBannerView: View {
    @Environment(\.lcuiChatSettings) private var settings

    private let message: Text

    public init(message: Text) {
        self.message = message
    }

    public var body: some View {
        message
            .font(settings.theme.bannerFont)
            .foregroundStyle(settings.theme.primaryColor)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(settings.theme.bannerBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


@available(iOS 16, *)
#Preview("Banner - Short Text") {
    VStack(spacing: 8) {
        LCUIChatErrorBannerView(message: Text("No connection"))
        LCUIChatComposerView(onSend: { _ in }, onAttachmentTapped: {})
    }
    .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("Banner - Long Text") {
    VStack(spacing: 8) {
        LCUIChatErrorBannerView(
            message: Text("We couldn't send your message. Please check your internet connection and try again.")
        )
        LCUIChatComposerView(onSend: { _ in }, onAttachmentTapped: {})
    }
    .lcuiChatSettings(.init())
}
