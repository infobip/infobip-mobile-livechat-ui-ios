//
//  LCUIChatScreenView.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

@available(iOS 16, *)
public struct LCUIChatScreenView<WebContent: View, Composer: LCUIChatComposing>: View {
    @Environment(\.lcuiChatSettings) private var settings

    private var colors: LCUIChatTheme.Colors { settings.theme.colors }
    private var layout: LCUIChatTheme.Layout { settings.theme.layout }

    private let composerType: Composer.Type
    private let isComposerEnabled: Bool
    private let showsComposer: Bool
    private let error: LCUIChatError?
    private let bannerMessage: Text?
    private let onBannerTapped: () -> Void
    private let onSend: (String) -> Void
    private let onAttachmentTapped: () -> Void
    private let onTextChange: (String) -> Void
    private let embedsNavigationStack: Bool
    private let showsCustomBackButton: Bool
    private let onBackButtonTapped: () -> Void
    private let webContent: () -> WebContent

    public init(
        composer: Composer.Type,
        isComposerEnabled: Bool = true,
        showsComposer: Bool = true,
        error: LCUIChatError? = nil,
        bannerMessage: Text? = nil,
        onBannerTapped: @escaping () -> Void = {},
        onSend: @escaping (String) -> Void,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in },
        embedsNavigationStack: Bool = true,
        showsCustomBackButton: Bool = false,
        onBackButtonTapped: @escaping () -> Void = {},
        @ViewBuilder webContent: @escaping () -> WebContent
    ) {
        self.composerType = composer
        self.isComposerEnabled = isComposerEnabled
        self.showsComposer = showsComposer
        self.error = error
        self.bannerMessage = bannerMessage
        self.onBannerTapped = onBannerTapped
        self.onSend = onSend
        self.onAttachmentTapped = onAttachmentTapped
        self.onTextChange = onTextChange
        self.embedsNavigationStack = embedsNavigationStack
        self.showsCustomBackButton = showsCustomBackButton
        self.onBackButtonTapped = onBackButtonTapped
        self.webContent = webContent
    }

    public var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { navigationBar }
            } else {
                // Case when navigation is hosted inside an existing navigation container (ie UIKit's UINavigationController, or a SwiftUI NavigationStack)
                navigationBar
            }
        }
        .tint(colors.primary)
    }

    private var usesLiquidGlassChrome: Bool {
        if #available(iOS 26, *) {
            return layout.prefersLiquidGlass
        }
        return false
    }

    private var navigationBar: some View {
        let navBarContent = content
            .navigationTitle(settings.texts.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(showsCustomBackButton)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showsCustomBackButton {
                        Button(action: onBackButtonTapped) { settings.icons.navigation.back }
                    }
                }
            }
        return Group {
            if usesLiquidGlassChrome {
                navBarContent // system's will provide liquid glass effect
            } else {
                navBarContent
                    .toolbarBackground(colors.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ZStack {
                if let error {
                    LCUIChatFullScreenErrorView(error: error)
                } else {
                    webContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // These negative paddings lets the chat content grow back out of it by the wanted overlap when liquid glass is used. No `ignoresSafeArea` here, as it would undo any padding applied inside it
            .padding(.top, -navigationBarOverlap)
            .padding(.bottom, -composerOverlap)
            .overlay(alignment: .bottom) {
                // Overlaid, not stacked, so a transient banner never reflows the widget
                if error == nil, let bannerMessage {
                    LCUIChatErrorBannerView(message: bannerMessage, onTapped: onBannerTapped)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            .animation(.default, value: bannerMessage != nil)

            if showsComposer, error == nil {
                composerType.init(
                    configuration: LCUIChatComposerConfiguration(
                        isEnabled: isComposerEnabled,
                        onSend: onSend,
                        onAttachmentTapped: onAttachmentTapped,
                        onTextChange: onTextChange
                    )
                )
            }
        }
        // Behind the whole stack, as the chat content no longer reaches the bottom of the screen
        .background(colors.background.ignoresSafeArea())
    }

    private var composerOverlap: CGFloat {
        guard showsComposer, error == nil else { return 0 }
        return layout.composerContentOverlap
    }

    // How far the chat content reaches above the bottom of the navigation bar. Left at zero without liquid
    // glass, where the bar is opaque and anything underneath it would only be hidden
    private var navigationBarOverlap: CGFloat {
        guard usesLiquidGlassChrome, error == nil else { return 0 }
        return layout.navigationBarContentOverlap
    }
}

// Default composer.
@available(iOS 16, *)
public extension LCUIChatScreenView where Composer == LCUIChatComposerView {
    init(
        isComposerEnabled: Bool = true,
        showsComposer: Bool = true,
        error: LCUIChatError? = nil,
        bannerMessage: Text? = nil,
        onBannerTapped: @escaping () -> Void = {},
        onSend: @escaping (String) -> Void,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in },
        embedsNavigationStack: Bool = true,
        showsCustomBackButton: Bool = false,
        onBackButtonTapped: @escaping () -> Void = {},
        @ViewBuilder webContent: @escaping () -> WebContent
    ) {
        self.init(
            composer: LCUIChatComposerView.self,
            isComposerEnabled: isComposerEnabled,
            showsComposer: showsComposer,
            error: error,
            bannerMessage: bannerMessage,
            onBannerTapped: onBannerTapped,
            onSend: onSend,
            onAttachmentTapped: onAttachmentTapped,
            onTextChange: onTextChange,
            embedsNavigationStack: embedsNavigationStack,
            showsCustomBackButton: showsCustomBackButton,
            onBackButtonTapped: onBackButtonTapped,
            webContent: webContent
        )
    }
}

@available(iOS 16, *)
#Preview("Chat") {
    LCUIChatScreenView(
        onSend: { _ in }
    ) {
        Text("Web content placeholder")
    }
    .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("Error") {
    LCUIChatScreenView(
        error: LCUIChatError(title: Text("Something went wrong"), subtitle: Text("Please try again later.")),
        onSend: { _ in }
    ) {
        Text("Web content placeholder")
    }
    .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("Banner") {
    LCUIChatScreenView(
        bannerMessage: Text("No connection"),
        onBannerTapped: { print("Banner tapped") },
        onSend: { _ in }
    ) {
        Text("Web content placeholder")
    }
    .lcuiChatSettings(.init())
}
