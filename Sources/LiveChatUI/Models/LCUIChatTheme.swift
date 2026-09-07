//
//  LCUIChatTheme.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

public struct LCUIChatTheme: Equatable, Sendable {
    public private(set) var primaryColor: Color
    public private(set) var secondaryColor: Color
    public private(set) var backgroundColor: Color
    public private(set) var prefersLiquidGlass: Bool // value ignored below iOS 26
    public private(set) var sendButtonBackgroundColor: Color?
    public private(set) var sendButtonTintColor: Color?
    public private(set) var composerContentOverlap: CGFloat  // Overlap of the webview under the composer, used for the liquid glass effect
    public private(set) var navigationBarContentOverlap: CGFloat // Overlap of the webview under the nav bar, used for the liquid glass effect
    public private(set) var bannerFont: Font
    public private(set) var bannerBackgroundColor: Color?

    private static let disabledAlpha: Double = 0.35

    public init(
        primaryColor: Color,
        secondaryColor: Color,
        backgroundColor: Color,
        prefersLiquidGlass: Bool = true,
        sendButtonBackgroundColor: Color? = nil,
        sendButtonTintColor: Color? = nil,
        composerContentOverlap: CGFloat = 30,
        navigationBarContentOverlap: CGFloat = 11, // minimum value for a visible effect
        bannerFont: Font = .subheadline,
        bannerBackgroundColor: Color
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.prefersLiquidGlass = prefersLiquidGlass
        self.sendButtonBackgroundColor = sendButtonBackgroundColor
        self.sendButtonTintColor = sendButtonTintColor
        self.composerContentOverlap = composerContentOverlap
        self.navigationBarContentOverlap = navigationBarContentOverlap
        self.bannerFont = bannerFont
        self.bannerBackgroundColor = bannerBackgroundColor
    }

    public var primaryColorDisabled: Color { primaryColor.opacity(Self.disabledAlpha) }
    public var secondaryColorDisabled: Color { secondaryColor.opacity(Self.disabledAlpha) }

    public var resolvedSendButtonBackgroundColor: Color { sendButtonBackgroundColor ?? primaryColor }
    public var resolvedSendButtonTintColor: Color { sendButtonTintColor ?? .white }
    public var resolvedSendButtonBackgroundColorDisabled: Color { resolvedSendButtonBackgroundColor.opacity(Self.disabledAlpha) }
    public var resolvedSendButtonTintColorDisabled: Color { resolvedSendButtonTintColor.opacity(Self.disabledAlpha) }

    public static let `default` = LCUIChatTheme(
        primaryColor: .black,
        secondaryColor: .black.opacity(0.5),
        backgroundColor: Color(.systemBackground),
        bannerBackgroundColor: Color.red
    )
}

private struct LCUIChatSettingsKey: EnvironmentKey {
    static let defaultValue: LCUIChatSettings = .init()
}

public extension EnvironmentValues {
    var lcuiChatSettings: LCUIChatSettings {
        get { self[LCUIChatSettingsKey.self] }
        set { self[LCUIChatSettingsKey.self] = newValue }
    }
}

public extension View {
    func lcuiChatSettings(_ settings: LCUIChatSettings) -> some View {
        environment(\.lcuiChatSettings, settings)
    }
}
