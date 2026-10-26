//
//  LCUIChatThemeTests.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import XCTest
import SwiftUI
@testable import LiveChatUI

final class LCUIChatThemeTests: XCTestCase {
    func testCustomLightPrimaryColorPropagatesToLightColors() {
        let theme = LCUIChatTheme(lightPrimaryColor: .red, currentColorMode: .light)
        XCTAssertEqual(theme.colors.primary, .red)
    }

    func testCustomDarkPrimaryColorPropagatesToDarkColors() {
        let theme = LCUIChatTheme(darkPrimaryColor: .green, currentColorMode: .dark)
        XCTAssertEqual(theme.colors.primary, .green)
    }

    func testLightSendTintKeepsWhiteAtThresholdAndFallsBackToBlack() {
        var theme = LCUIChatTheme(lightPrimaryColor: Color(lcHex: "757575"))
        XCTAssertEqual(theme.lightSendTintColor, .white)
        XCTAssertEqual(theme.colors.sendButtonTint, .white)

        theme.lightPrimaryColor = Color(lcHex: "777777")
        XCTAssertEqual(theme.lightSendTintColor, .black)
        XCTAssertEqual(theme.colors.sendButtonTint, .black)
    }

    func testDarkSendTintTracksPrimaryColor() {
        var theme = LCUIChatTheme(darkPrimaryColor: Color(lcHex: "555555"), currentColorMode: .dark)
        XCTAssertEqual(theme.darkSendTintColor, .white)
        XCTAssertEqual(theme.colors.sendButtonTint, .white)

        theme.darkPrimaryColor = .white
        XCTAssertEqual(theme.darkSendTintColor, Color(lcHex: "141414"))
        XCTAssertEqual(theme.colors.sendButtonTint, Color(lcHex: "141414"))
    }

    func testActiveAndDisabledSendTintFollowColorMode() {
        var theme = LCUIChatTheme(
            lightPrimaryColor: Color(lcHex: "777777"),
            darkPrimaryColor: Color(lcHex: "555555")
        )
        XCTAssertEqual(theme.activeSendButtonTintColor, .black)
        XCTAssertEqual(theme.sendButtonTintColorDisabled, Color.black.opacity(0.75))

        theme.currentColorMode = .dark
        XCTAssertEqual(theme.activeSendButtonTintColor, .white)
        XCTAssertEqual(theme.sendButtonTintColorDisabled, Color.white.opacity(0.75))
    }

    func testSendTintUpdatesWhenDynamicPrimaryChangesAppearance() {
        var theme = LCUIChatTheme(darkPrimaryColor: Color(uiColor: .label))

        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            XCTAssertEqual(theme.darkSendTintColor, .white)
        }
        UITraitCollection(userInterfaceStyle: .dark).performAsCurrent {
            theme.currentColorMode = .dark
            XCTAssertEqual(theme.darkSendTintColor, Color(lcHex: "141414"))
            XCTAssertEqual(theme.colors.sendButtonTint, Color(lcHex: "141414"))
        }
    }

    func testNonRGBPrimaryColorDoesNotCrashTintSelection() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let pattern = Color(uiColor: UIColor(patternImage: image))
        let theme = LCUIChatTheme(lightPrimaryColor: pattern, darkPrimaryColor: pattern)

        XCTAssertEqual(theme.lightSendTintColor, .white)
        XCTAssertEqual(theme.darkSendTintColor, Color(lcHex: "141414"))
    }

    func testMutatingDarkPrimaryColorAfterInitOnlyAffectsDarkColors() {
        var theme = LCUIChatTheme(lightPrimaryColor: .red, darkPrimaryColor: .white, currentColorMode: .light)
        let lightPrimaryBefore = theme.colors.primary

        theme.darkPrimaryColor = .blue

        theme.currentColorMode = .dark
        XCTAssertEqual(theme.colors.primary, .blue)

        theme.currentColorMode = .light
        XCTAssertEqual(theme.colors.primary, lightPrimaryBefore)
    }

    func testMutatingLightPrimaryColorAfterInitOnlyAffectsLightColors() {
        var theme = LCUIChatTheme(lightPrimaryColor: .red, darkPrimaryColor: .white, currentColorMode: .dark)
        let darkPrimaryBefore = theme.colors.primary

        theme.lightPrimaryColor = .orange

        theme.currentColorMode = .light
        XCTAssertEqual(theme.colors.primary, .orange)

        theme.currentColorMode = .dark
        XCTAssertEqual(theme.colors.primary, darkPrimaryBefore)
    }
}

final class LCUIChatColorHexTests: XCTestCase {
    func testValidSixDigitHex() {
        XCTAssertEqual(Color(lcHex: "FFFFFF"), Color(red: 1, green: 1, blue: 1))
        XCTAssertEqual(Color(lcHex: "000000"), Color(red: 0, green: 0, blue: 0))
    }

    func testHashPrefixedHexParsesCorrectly() {
        XCTAssertEqual(Color(lcHex: "#FFFFFF"), Color(red: 1, green: 1, blue: 1))
    }

    func testAlphaDefaultsToOpaque() {
        XCTAssertEqual(Color(lcHex: "FFFFFF"), Color(red: 1, green: 1, blue: 1, opacity: 1))
    }

    func testCustomAlphaIsApplied() {
        XCTAssertEqual(Color(lcHex: "FFFFFF", alpha: 0.5), Color(red: 1, green: 1, blue: 1, opacity: 0.5))
    }

    // Invalid input ("ZZZZZZ", 3-digit shorthand, empty string, etc.) now trips
    // `assertionFailure` before falling back to black, which traps debug test runs.
    // That's intentional — it surfaces bad hex strings during development instead of
    // silently rendering black — so those cases aren't exercised here.
}

// Views (LCUIChatScreenView, LCUIChatAttachmentPreview, LCUIChatAttachmentPickerView,
// LCUIChatComposerView) all resolve their background/tint via
// `@Environment(\.lcuiChatSettings) -> settings.theme.colors`. This exercises that same
// resolution path end-to-end through `LCUIChatSettings`, without needing a snapshot-testing
// dependency to assert on actual rendered pixels.
final class LCUIChatSettingsColorModePropagationTests: XCTestCase {
    func testDarkColorModePropagatesThroughSettingsToBackgroundAndPrimary() {
        let theme = LCUIChatTheme(currentColorMode: .dark)
        let settings = LCUIChatSettings(theme: theme)

        XCTAssertEqual(settings.theme.colors.background, Color(lcHex: "141414"))
        XCTAssertEqual(settings.theme.colors.primary, .white)
    }

    func testLightColorModePropagatesThroughSettingsToBackgroundAndPrimary() {
        let theme = LCUIChatTheme(lightPrimaryColor: .red, currentColorMode: .light)
        let settings = LCUIChatSettings(theme: theme)

        XCTAssertEqual(settings.theme.colors.background, Color(.systemBackground))
        XCTAssertEqual(settings.theme.colors.primary, .red)
    }
}
