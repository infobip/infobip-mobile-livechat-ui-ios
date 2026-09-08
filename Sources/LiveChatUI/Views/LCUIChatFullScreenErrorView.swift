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

    private var colors: LCUIChatTheme.Colors { settings.theme.colors }

    private let error: LCUIChatError

    public init(error: LCUIChatError) {
        self.error = error
    }

    public var body: some View {
        VStack(spacing: 12) {
            ZStack {
                let alertColor = settings.theme.banner.backgroundColor
                Circle()
                    .fill(alertColor.opacity(0.1))
                    .frame(width: 72, height: 72)
                settings.icons.fullScreenErrorIcon
                    .font(.system(size: 32))
                    .foregroundStyle(alertColor)
            }

            if let title = error.title {
                title
                    .font(.title2.bold())
                    .foregroundStyle(colors.primary)
                    .multilineTextAlignment(.center)
            }

            if let subtitle = error.subtitle {
                subtitle
                    .font(.body)
                    .foregroundStyle(colors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

@available(iOS 16, *)
#Preview {
    LCUIChatFullScreenErrorView(
        error: LCUIChatError(title: Text("Something went wrong"), subtitle: Text("Please try again later."))
    )
    .lcuiChatSettings(.init())
}
