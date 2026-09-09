//
//  LCUIChatAttachmentStoreTests.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import XCTest
import UniformTypeIdentifiers
@testable import LiveChatUI

final class LCUIChatFileNameSanitisationTests: XCTestCase {
    private static let generatedNamePattern = #"^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.jpeg$"#

    private func sanitized(_ input: String?, _ type: UTType? = .jpeg) -> String {
        LCUIChatAttachmentStore.sanitizedFileName(input, contentType: type)
    }

    func testKeepsOrdinaryNames() {
        XCTAssertEqual(sanitized("holiday photo-2.jpg"), "holiday photo-2.jpg")
        XCTAssertEqual(sanitized("report_final.PDF", .pdf), "report_final.PDF")
    }

    /// A picked file's name is attacker-influenced. Quotes and CR/LF in a `Content-Disposition`
    /// header are the classic header-injection primitive.
    func testStripsHeaderInjectionCharacters() {
        let result = sanitized("evil\"; name=\"x\r\nX-Injected: 1.jpg")
        XCTAssertFalse(result.contains("\""))
        XCTAssertFalse(result.contains("\r"))
        XCTAssertFalse(result.contains("\n"))
        XCTAssertFalse(result.contains(";"))
    }

    func testStripsControlCharactersAndSeparators() {
        let result = sanitized("a\u{0}b\u{7}c/d\\e:f.jpg")
        XCTAssertFalse(result.contains("/"))
        XCTAssertFalse(result.contains("\\"))
        XCTAssertFalse(result.contains(":"))
        XCTAssertFalse(result.unicodeScalars.contains { $0.properties.generalCategory == .control })
    }

    func testCollapsesTraversalSequences() {
        XCTAssertFalse(sanitized("../../etc/passwd").contains(".."))
        XCTAssertFalse(sanitized("....//....//x.jpg").contains(".."))
    }

    /// "." and ".." would resolve to a directory rather than a file.
    func testDotOnlyNamesFallBackToAGeneratedName() {
        for input in [".", "..", "...", " ", ""] {
            let result = sanitized(input)
            XCTAssertNotNil(
                result.range(of: Self.generatedNamePattern, options: .regularExpression),
                "unexpected result \(result) for \(input.debugDescription)"
            )
        }
    }

    func testNilNameFallsBackToAGeneratedName() {
        XCTAssertNotNil(sanitized(nil).range(of: Self.generatedNamePattern, options: .regularExpression))
    }

    func testCapsLengthWhilePreservingTheExtension() {
        let result = sanitized(String(repeating: "a", count: 500) + ".jpg")
        XCTAssertLessThanOrEqual(result.count, 128)
        XCTAssertEqual(URL(fileURLWithPath: result).pathExtension, "jpg")
    }

    func testAddsAnExtensionWhenTheNameHasNone() {
        XCTAssertEqual(sanitized("scan", .pdf), "scan.pdf")
    }

    func testLeavesNameAloneWhenNoContentTypeIsKnown() {
        XCTAssertEqual(sanitized("mystery", nil), "mystery")
    }

    /// The generated stem must be Gregorian and ASCII regardless of the device's calendar — a
    /// user on a Buddhist or Persian calendar previously got a filename with a different year.
    func testGeneratedNameUsesAFixedGregorianFormat() {
        let result = LCUIChatAttachmentStore.generatedFileName(contentType: .jpeg)
        XCTAssertNotNil(
            result.range(of: Self.generatedNamePattern, options: .regularExpression),
            "\(result) does not match the fixed timestamp format"
        )
    }

    func testDestinationsAreUniqueForTheSameName() throws {
        defer { LCUIChatAttachmentStore.removeAll() }
        let first = try LCUIChatAttachmentStore.destination(fileName: "photo.jpg")
        let second = try LCUIChatAttachmentStore.destination(fileName: "photo.jpg")
        XCTAssertNotEqual(first, second)
        XCTAssertTrue(first.lastPathComponent.hasSuffix("-photo.jpg"))
    }
}

final class LCUIChatAttachmentKindTests: XCTestCase {
    func testClassifiesImages() {
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .jpeg), .image)
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .png), .image)
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .heic), .image)
    }

    func testClassifiesVideos() {
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .mpeg4Movie), .video)
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .quickTimeMovie), .video)
    }

    func testClassifiesEverythingElseAsDocument() {
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .pdf), .document)
        XCTAssertEqual(LCUIChatAttachmentKind(contentType: .plainText), .document)
    }

    /// Regression: a hand-maintained extension list classified `.srt` — a subtitle *text* file —
    /// as a video, which offered the camera for a configuration that permitted no media at all.
    func testSubtitleFilesAreNotVideos() throws {
        let subtitle = try XCTUnwrap(UTType(filenameExtension: "srt"))
        XCTAssertNotEqual(LCUIChatAttachmentKind(contentType: subtitle), .video)
    }
}

final class LCUIChatAttachmentEqualityTests: XCTestCase {
    private func attachment(fileName: String) -> LCUIChatAttachment {
        LCUIChatAttachment(
            fileName: fileName,
            fileURL: URL(fileURLWithPath: "/tmp/\(fileName)"),
            byteCount: 1,
            contentType: .jpeg,
            kind: .image
        )
    }

    /// Equality is identity-based on purpose: comparing payloads would have SwiftUI diffing
    /// memcmp megabytes on every re-evaluation.
    func testEqualityIsIdentityBased() {
        let first = attachment(fileName: "a.jpg")
        XCTAssertEqual(first, first)
        XCTAssertNotEqual(first, attachment(fileName: "a.jpg"))
    }
}
