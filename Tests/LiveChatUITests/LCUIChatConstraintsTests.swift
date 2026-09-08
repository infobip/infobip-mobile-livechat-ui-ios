//
//  LCUIChatConstraintsTests.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import XCTest
import PhotosUI
import UniformTypeIdentifiers
@testable import LiveChatUI

final class LCUIChatConstraintsTests: XCTestCase {
    func testDefaultsAllowImagesAndVideos() {
        let constraints = LCUIChatConstraints()
        XCTAssertTrue(constraints.allowsImageContent)
        XCTAssertTrue(constraints.allowsVideoContent)
        XCTAssertTrue(constraints.allowsCameraCapture)
    }

    func testImagesOnlyConfigurationRejectsVideo() {
        let constraints = LCUIChatConstraints(allowedContentTypes: [.jpeg, .png])
        XCTAssertTrue(constraints.allowsImageContent)
        XCTAssertFalse(constraints.allowsVideoContent)
        XCTAssertEqual(constraints.photoLibraryFilter, .images)
    }

    func testVideosOnlyConfiguration() {
        let constraints = LCUIChatConstraints(allowedContentTypes: [.mpeg4Movie])
        XCTAssertFalse(constraints.allowsImageContent)
        XCTAssertTrue(constraints.allowsVideoContent)
        XCTAssertEqual(constraints.photoLibraryFilter, .videos)
    }

    /// The photo library has nothing pickable, so its row must be hidden rather than opening an
    /// empty picker.
    func testDocumentOnlyConfigurationHidesTheGalleryAndCamera() {
        let constraints = LCUIChatConstraints(allowedContentTypes: [.pdf])
        XCTAssertNil(constraints.photoLibraryFilter)
        XCTAssertFalse(constraints.allowsCameraCapture)
    }

    func testEmptyConfigurationMeansUnrestricted() {
        let constraints = LCUIChatConstraints(allowedContentTypes: [])
        XCTAssertTrue(constraints.allowsImageContent)
        XCTAssertTrue(constraints.allowsVideoContent)
    }

    /// `UIDocumentPickerViewController` requires at least one content type, so an unrestricted
    /// configuration must not produce an empty array.
    func testDocumentPickerTypesAreNeverEmpty() {
        XCTAssertEqual(LCUIChatConstraints(allowedContentTypes: []).documentPickerContentTypes, [.item])
        XCTAssertFalse(LCUIChatConstraints(allowedFileExtensions: ["notatype"]).documentPickerContentTypes.isEmpty)
    }

    func testFileExtensionInitResolvesKnownExtensions() {
        let constraints = LCUIChatConstraints(allowedFileExtensions: ["jpg", "mp4"])
        XCTAssertTrue(constraints.allowsImageContent)
        XCTAssertTrue(constraints.allowsVideoContent)
    }

    /// An unknown extension makes `UTType(filenameExtension:)` synthesise an opaque `dyn.…` type
    /// rather than returning nil, so only *declared* types may be accepted.
    func testFileExtensionInitDropsUndeclaredExtensions() {
        let constraints = LCUIChatConstraints(allowedFileExtensions: ["jpg", "definitely-not-real"])
        XCTAssertEqual(constraints.allowedContentTypes, [.jpeg])
        XCTAssertTrue(constraints.allowsImageContent)
        XCTAssertFalse(constraints.allowedContentTypes.contains { !$0.isDeclared })
    }

    func testCharacterLimitDefaults() {
        let constraints = LCUIChatConstraints()
        XCTAssertEqual(constraints.maximumCharacterCount, 4096)
        XCTAssertEqual(constraints.charCounterVisibleThreshold, 4000)
        XCTAssertLessThan(constraints.charCounterVisibleThreshold, constraints.maximumCharacterCount)
        XCTAssertEqual(constraints.maximumAttachmentByteCount, 25 * 1024 * 1024)
    }
}
