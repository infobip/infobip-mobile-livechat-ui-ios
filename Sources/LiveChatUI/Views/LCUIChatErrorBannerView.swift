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

    private var banner: LCUIChatTheme.Banner { settings.theme.banner }
    private let padding: CGFloat = 16
    private let radius: CGFloat = 14
    private let message: Text
    private let onTapped: () -> Void

    public init(message: Text, onTapped: @escaping () -> Void = {}) {
        self.message = message
        self.onTapped = onTapped
    }

    public var body: some View {
        message
            .font(banner.font)
            .foregroundStyle(banner.fontColor)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(banner.backgroundColor)
            .clipShape(
                RoundedRectangle(cornerRadius: radius,
                                 style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapped)
    }
}


@available(iOS 16, *)
#Preview("Banner - Short Text") {
    VStack(spacing: 8) {
        LCUIChatErrorBannerView(message: Text("No connection"), onTapped: { print("Banner tapped") })
            .padding(.horizontal, 12)
        LCUIChatComposerView(onSend: { _ in }, onAttachmentTapped: {})
    }
    .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("Banner - Long Text") {
    VStack(spacing: 8) {
        LCUIChatErrorBannerView(
            message: Text("We couldn't send your message. Please check your internet connection and try again."),
            onTapped: { print("Banner tapped") }
        )
        .padding(.horizontal, 12)
        LCUIChatComposerView(onSend: { _ in }, onAttachmentTapped: {})
    }
    .lcuiChatSettings(.init())
}
