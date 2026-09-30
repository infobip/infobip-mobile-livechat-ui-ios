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
