//
//  LCUIChatTheme.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

public struct LCUIChatTheme: Equatable, Sendable {
    public struct Colors: Equatable, Sendable {
        public private(set) var primary: Color
        public private(set) var secondary: Color
        public private(set) var background: Color
        public private(set) var sendButtonBackground: Color
        public private(set) var sendButtonTint: Color

        public init(
            primary: Color = .black,
            secondary: Color = Color(red: 0.3608, green: 0.3569, blue: 0.3490), // #5C5B59
            background: Color = Color(.systemBackground),
            sendButtonBackground: Color = .black,
            sendButtonTint: Color = .white
        ) {
            self.primary = primary
            self.secondary = secondary
            self.background = background
            self.sendButtonBackground = sendButtonBackground
            self.sendButtonTint = sendButtonTint
        }
    }

    public struct Layout: Equatable, Sendable {
        public private(set) var prefersLiquidGlass: Bool // value ignored below iOS 26
        public private(set) var composerContentOverlap: CGFloat  // Overlap of the webview under the composer, used for the liquid glass effect
        public private(set) var navigationBarContentOverlap: CGFloat // Overlap of the webview under the nav bar, used for the liquid glass effect

        public init(
            prefersLiquidGlass: Bool = true,
            composerContentOverlap: CGFloat = 10, // 30 for the optimal result, but only if no auto message btn exists
            navigationBarContentOverlap: CGFloat = 11
        ) {
            self.prefersLiquidGlass = prefersLiquidGlass
            self.composerContentOverlap = composerContentOverlap
            self.navigationBarContentOverlap = navigationBarContentOverlap
        }
    }

    public struct Banner: Equatable, Sendable {
        public private(set) var font: Font
        public private(set) var backgroundColor: Color

        public init(
            font: Font = .subheadline,
            backgroundColor: Color = Color(red: 0.702, green: 0.149, blue: 0.118) // #B3261E
        ) {
            self.font = font
            self.backgroundColor = backgroundColor
        }
    }

    public private(set) var colors: Colors
    public private(set) var layout: Layout
    public private(set) var banner: Banner

    private static let disabledAlpha: Double = 0.35
    private static let disabledAlphaDarker: Double = 0.75

    public init(
        colors: Colors = Colors(),
        layout: Layout = Layout(),
        banner: Banner = Banner()
    ) {
        self.colors = colors
        self.layout = layout
        self.banner = banner
    }

    public var primaryColorDisabled: Color { colors.primary.opacity(Self.disabledAlpha) }
    public var secondaryColorDisabled: Color { colors.secondary.opacity(Self.disabledAlpha) }

    public var sendButtonTintColorDisabled: Color { colors.sendButtonTint.opacity(Self.disabledAlphaDarker) }
    public var sendButtonBackgroundColorDisabled: Color { colors.sendButtonBackground.opacity(Self.disabledAlphaDarker) }

    public static let `default` = LCUIChatTheme()
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
