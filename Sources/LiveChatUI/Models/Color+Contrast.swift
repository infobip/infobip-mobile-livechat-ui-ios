//
//  Color+Contrast.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import UIKit

private struct LCUIRGBA {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    static let black = LCUIRGBA(red: 0, green: 0, blue: 0, alpha: 1)
    static let white = LCUIRGBA(red: 1, green: 1, blue: 1, alpha: 1)

    init?(_ color: Color) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        func clamped(_ value: CGFloat) -> Double {
            min(max(Double(value), 0), 1)
        }
        self.red = clamped(red)
        self.green = clamped(green)
        self.blue = clamped(blue)
        self.alpha = clamped(alpha)
    }

    private init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    func composited(over background: LCUIRGBA) -> LCUIRGBA {
        precondition(background.alpha >= 0.999, "LiveChatUI: contrast underlay must be opaque")
        return LCUIRGBA(
            red: red * alpha + background.red * (1 - alpha),
            green: green * alpha + background.green * (1 - alpha),
            blue: blue * alpha + background.blue * (1 - alpha),
            alpha: 1
        )
    }

    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045
                ? channel / 12.92
                : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red)
            + 0.7152 * linear(green)
            + 0.0722 * linear(blue)
    }

    func contrastRatio(against background: LCUIRGBA) -> Double {
        let lighter = max(relativeLuminance, background.relativeLuminance)
        let darker = min(relativeLuminance, background.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

extension Color {
    /// Keeps this tint when it meets 4.5:1 against the rendered background; otherwise uses the better of black or white.
    /// If the background cannot be measured, preserves the preferred tint.
    func sendTintEnsuringContrast(against background: Color, over underlay: Color) -> Color {
        guard let backgroundRGBA = LCUIRGBA(background), let underlayRGBA = LCUIRGBA(underlay) else {
            return self
        }
        let renderedBackground = backgroundRGBA.composited(over: underlayRGBA)
        if let tintRGBA = LCUIRGBA(self) {
            let originalRatio = tintRGBA
                .composited(over: renderedBackground)
                .contrastRatio(against: renderedBackground)
            if originalRatio >= 4.5 { return self }
        }

        let blackRatio = LCUIRGBA.black.contrastRatio(against: renderedBackground)
        let whiteRatio = LCUIRGBA.white.contrastRatio(against: renderedBackground)
        return blackRatio >= whiteRatio ? .black : .white
    }
}
