//
//  LCUIChatFullScreenErrorView.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

// TODO: this view will be replaced by a new design of a banner, it won't be full screen
@available(iOS 16, *)
public struct LCUIChatFullScreenErrorView: View {
    @Environment(\.lcuiChatSettings) private var settings

    private let error: LCUIChatError
    private let onRetry: () -> Void

    public init(error: LCUIChatError, onRetry: @escaping () -> Void = {}) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 48))
                .foregroundStyle(settings.theme.secondaryColor)

            if let title = error.title {
                title
                    .font(.headline)
                    .foregroundStyle(settings.theme.primaryColor)
                    .multilineTextAlignment(.center)
            }

            if let subtitle = error.subtitle {
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(settings.theme.secondaryColor)
                    .multilineTextAlignment(.center)
            }

            Button("Retry", action: onRetry)
                .foregroundStyle(settings.theme.primaryColor)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.theme.backgroundColor)
    }
}

@available(iOS 16, *)
#Preview {
    LCUIChatFullScreenErrorView(
        error: LCUIChatError(title: Text("Something went wrong"), subtitle: Text("Please try again later."))
    )
    .lcuiChatSettings(.init())
}
