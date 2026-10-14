//
//  LCUIChatPreviewAttachmentTests.swift
//  LiveChatUI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import XCTest
@testable import LiveChatUI

final class LCUIChatPreviewAttachmentTests: XCTestCase {
    func testDocumentQuickLookURLRequiresLocalFileURL() {
        let remoteAttachment = LCUIChatPreviewAttachment(
            fileName: "document.pdf",
            kind: .document,
            sourceURL: URL(string: "https://example.com/document.pdf")!
        )
        let fileURL = URL(fileURLWithPath: "/tmp/document.pdf")
        let localAttachment = LCUIChatPreviewAttachment(
            fileName: "document.pdf",
            kind: .document,
            sourceURL: fileURL
        )

        XCTAssertNil(remoteAttachment.quickLookURL)
        XCTAssertEqual(localAttachment.quickLookURL, fileURL)
    }

    func testNonDocumentAttachmentsDoNotExposeQuickLookURL() {
        let sourceURL = URL(string: "https://example.com/attachment")!

        XCTAssertNil(LCUIChatPreviewAttachment(fileName: nil, kind: .image, sourceURL: sourceURL).quickLookURL)
        XCTAssertNil(LCUIChatPreviewAttachment(fileName: nil, kind: .video, sourceURL: sourceURL).quickLookURL)
    }

    func testPreviewAttachmentRetainsOriginalURLSeparatelyFromStagedSource() {
        let remoteURL = URL(string: "https://example.com/document.pdf")!
        let stagedURL = URL(fileURLWithPath: "/tmp/document.pdf")
        let attachment = LCUIChatPreviewAttachment(
            fileName: "document.pdf",
            kind: .document,
            sourceURL: stagedURL,
            originalURL: remoteURL
        )

        XCTAssertEqual(attachment.sourceURL, stagedURL)
        XCTAssertEqual(attachment.originalURL, remoteURL)
        XCTAssertEqual(attachment.quickLookURL, stagedURL)
        XCTAssertEqual(attachment.previewFallbackURL, remoteURL)
    }

    func testPreviewFallbackURL_UsesRemoteSourceForMediaAndRejectsLocalFilesWithoutOriginal() {
        let imageURL = URL(string: "https://example.com/image.jpg")!
        let localDocumentURL = URL(fileURLWithPath: "/tmp/document.pdf")
        let image = LCUIChatPreviewAttachment(fileName: nil, kind: .image, sourceURL: imageURL)
        let localDocument = LCUIChatPreviewAttachment(fileName: "document.pdf", kind: .document, sourceURL: localDocumentURL)

        XCTAssertEqual(image.previewFallbackURL, imageURL)
        XCTAssertNil(localDocument.previewFallbackURL)
    }

    func testFailureCanBeReportedAgainForAnotherAttachmentOrUpdatedSource() {
        let id = UUID()
        let firstURL = URL(string: "https://example.com/first.mp4")!
        let secondURL = URL(string: "https://example.com/second.mp4")!
        let updatedURL = URL(string: "https://example.com/updated.mp4")!
        let first = LCUIChatPreviewAttachment(id: id, fileName: nil, kind: .video, sourceURL: firstURL)
        let renamed = LCUIChatPreviewAttachment(id: id, fileName: "renamed.mp4", kind: .video, sourceURL: firstURL)
        let second = LCUIChatPreviewAttachment(fileName: nil, kind: .video, sourceURL: secondURL)
        let updated = LCUIChatPreviewAttachment(id: id, fileName: nil, kind: .video, sourceURL: updatedURL)
        var tracker = LCUIChatPreviewFailureTracker()

        XCTAssertEqual(tracker.fallbackURLToReport(for: first), firstURL)
        XCTAssertNil(tracker.fallbackURLToReport(for: first))
        XCTAssertNil(tracker.fallbackURLToReport(for: renamed))
        XCTAssertEqual(tracker.fallbackURLToReport(for: second), secondURL)
        XCTAssertEqual(tracker.fallbackURLToReport(for: updated), updatedURL)
        XCTAssertNil(tracker.fallbackURLToReport(for: updated))
    }

    func testLocalAttachmentWithoutFallbackDoesNotConsumeFailureReport() {
        let id = UUID()
        let stagedURL = URL(fileURLWithPath: "/tmp/document.pdf")
        let remoteURL = URL(string: "https://example.com/document.pdf")!
        let local = LCUIChatPreviewAttachment(id: id, fileName: nil, kind: .document, sourceURL: stagedURL)
        let withOriginal = LCUIChatPreviewAttachment(
            id: id, fileName: nil, kind: .document, sourceURL: stagedURL, originalURL: remoteURL
        )
        var tracker = LCUIChatPreviewFailureTracker()

        XCTAssertNil(tracker.fallbackURLToReport(for: local))
        XCTAssertEqual(tracker.fallbackURLToReport(for: withOriginal), remoteURL)
    }
}
