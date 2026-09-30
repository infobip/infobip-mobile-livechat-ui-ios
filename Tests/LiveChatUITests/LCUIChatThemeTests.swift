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

    func testInvalidHexFallsBackToBlack() {
        XCTAssertEqual(Color(lcHex: "ZZZZZZ"), .black)
    }

    func testShorthandHexFallsBackToBlackRatherThanMisparsing() {
        XCTAssertEqual(Color(lcHex: "FFF"), .black)
    }

    func testEmptyStringFallsBackToBlack() {
        XCTAssertEqual(Color(lcHex: ""), .black)
    }
}
