//
//  LCUIChatTheme.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import UIKit

public struct LCUIChatTheme: Equatable, Sendable {
    public enum ColorMode: String, Hashable, Sendable {
        case light, dark, auto
    }

    public struct Colors: Equatable, Sendable {
        public var primary: Color
        public var secondary: Color
        public var background: Color
        public var sendButtonBackground: Color {
            return primary
        }
        public internal(set) var sendButtonTint: Color

        init(
            primary: Color,
            secondary: Color,
            background: Color,
            sendButtonTint: Color
        ) {
            self.primary = primary
            self.secondary = secondary
            self.background = background
            self.sendButtonTint = sendButtonTint
        }

        
        public static var light: Colors {
            return Colors(primary: Color(lcHex: "383533"),
                          secondary: Color(lcHex: "5C5B59"),
                          background: Color(.systemBackground),
                          sendButtonTint: .white)
        }

        public static var dark: Colors {
            return Colors(primary: .white,
                          secondary: .white,
                          background: Color(lcHex: "141414"),
                          sendButtonTint: Color(lcHex: "141414"))
        }
        
        
        @MainActor
        private static var systemInterfaceStyle: UIUserInterfaceStyle {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }?
                .windows

            let keyWindow = windows?.first(where: \.isKeyWindow) ?? windows?.first

            return (keyWindow?.traitCollection ?? UITraitCollection.current)
                .userInterfaceStyle
        }
        
        @MainActor
        public static func adaptRuntimeColorMode(for style: LCUIChatTheme.ColorMode) -> LCUIChatTheme.ColorMode {
            switch style {
            case .light: return .light
            case .dark: return .dark
            case .auto: return systemInterfaceStyle == .dark ? .dark : .light
            @unknown default: return systemInterfaceStyle == .dark ? .dark : .light
            }
        }
    }

    public struct Layout: Equatable, Sendable {
        public private(set) var prefersLiquidGlass: Bool // value ignored below iOS 26
        public private(set) var composerContentOverlap: CGFloat  // Overlap of the webview under the composer, used for the liquid glass effect
        public private(set) var navigationBarContentOverlap: CGFloat // Overlap of the webview under the nav bar, used for the liquid glass effect

        public init(
            prefersLiquidGlass: Bool = true,
            composerContentOverlap: CGFloat = 30,
            navigationBarContentOverlap: CGFloat = 0 // "soft" mode has nice visual effect but glitches when the webview scroll. Hard (default) has a hard cut in the effect that is not appealing. We leave it 0.
        ) {
            self.prefersLiquidGlass = prefersLiquidGlass
            self.composerContentOverlap = composerContentOverlap
            self.navigationBarContentOverlap = navigationBarContentOverlap
        }
    }

    public struct Banner: Equatable, Sendable {
        public private(set) var font: Font
        public private(set) var fontColor: Color
        public private(set) var backgroundColor: Color

        public init(
            font: Font = .subheadline,
            fontColor: Color = Color.white,
            backgroundColor: Color = Color(lcHex:"B3261E")
        ) {
            self.font = font
            self.fontColor = fontColor
            self.backgroundColor = backgroundColor
        }
    }

    private var lightColors: Colors
    private var darkColors: Colors
    public var currentColorMode: ColorMode = .light {
        didSet {
            // Semantic primary colors may resolve differently after an appearance change.
            refreshSendButtonTints()
        }
    }
    public var lightPrimaryColor: Color {
        didSet {
            lightColors.primary = lightPrimaryColor
            lightColors.sendButtonTint = Color.white.sendTintEnsuringContrast(
                against: lightPrimaryColor, over: .white)
        }
    }
    public var darkPrimaryColor: Color {
        didSet {
            darkColors.primary = darkPrimaryColor
            darkColors.sendButtonTint = darkColors.background.sendTintEnsuringContrast(
                against: darkPrimaryColor, over: darkColors.background)
        }
    }

    private mutating func refreshSendButtonTints() {
        lightColors.sendButtonTint = Color.white.sendTintEnsuringContrast(
            against: lightPrimaryColor, over: .white)
        darkColors.sendButtonTint = darkColors.background.sendTintEnsuringContrast(
            against: darkPrimaryColor, over: darkColors.background)
    }

    public var lightSendTintColor: Color { lightColors.sendButtonTint }
    public var darkSendTintColor: Color { darkColors.sendButtonTint }
    
    public var colors: Colors {
        return currentColorMode == .dark ? darkColors : lightColors
    }
    
    public var secondaryColor: Color {
        return currentColorMode == .dark ? darkColors.secondary : lightColors.secondary
    }

    public private(set) var layout: Layout
    public private(set) var banner: Banner

    private static let disabledAlpha: Double = 0.35
    private static let disabledAlphaDarker: Double = 0.75

    public init(
        lightPrimaryColor: Color = Color(lcHex: "383533"),
        darkPrimaryColor: Color = .white,
        currentColorMode: ColorMode = .light,
        layout: Layout = Layout(),
        banner: Banner = Banner()
    ) {
        self.lightColors = Colors.light
        self.darkColors = Colors.dark
        self.lightPrimaryColor = lightPrimaryColor
        self.darkPrimaryColor = darkPrimaryColor
        self.lightColors.primary = lightPrimaryColor
        self.darkColors.primary = darkPrimaryColor
        self.currentColorMode = currentColorMode
        self.layout = layout
        self.banner = banner
        refreshSendButtonTints()
    }

    public var primaryColorDisabled: Color { colors.primary.opacity(Self.disabledAlpha) }
    public var secondaryColorDisabled: Color { colors.secondary.opacity(Self.disabledAlpha) }

    internal var activeSendButtonTintColor: Color {
        currentColorMode == .dark ? darkSendTintColor : lightSendTintColor
    }
    public var sendButtonTintColorDisabled: Color {
        activeSendButtonTintColor.opacity(Self.disabledAlphaDarker)
    }
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

public extension Color {
    init(lcHex: String, alpha: Double = 1) {
        var sanitized = lcHex
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        var hexValue: UInt64 = 0
        let scanned = Scanner(string: sanitized).scanHexInt64(&hexValue)
        guard scanned, sanitized.count == 6 else {
            assertionFailure("LiveChatUI: \"\(lcHex)\" is not a valid 6-digit hex color; falling back to black.")
            self = .black
            return
        }
        let r = Double((hexValue & 0xFF0000) >> 16) / 255
        let g = Double((hexValue & 0x00FF00) >> 8) / 255
        let b = Double(hexValue & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }
}
