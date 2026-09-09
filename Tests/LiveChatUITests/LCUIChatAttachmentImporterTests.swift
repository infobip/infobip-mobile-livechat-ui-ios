//
//  LCUIChatAttachmentImporterTests.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import XCTest
import UniformTypeIdentifiers
@testable import LiveChatUI

final class LCUIChatAttachmentImporterTests: XCTestCase {
    private let importer = LCUIChatAttachmentImporter()
    private var scratch: URL!

    override func setUpWithError() throws {
        scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("lcui-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: scratch)
        LCUIChatAttachmentStore.removeAll()
    }

    private func makeFile(named name: String, byteCount: Int) throws -> URL {
        let url = scratch.appendingPathComponent(name)
        try Data(repeating: 0xAB, count: byteCount).write(to: url)
        return url
    }

    func testStagesASmallFileIntoPackageStorage() async throws {
        let source = try makeFile(named: "notes.pdf", byteCount: 1024)

        let attachment = try await importer.stage(
            source: source,
            isSecurityScoped: false,
            allowedContentTypes: [],
            maximumByteCount: 1024 * 1024
        )

        XCTAssertEqual(attachment.byteCount, 1024)
        XCTAssertEqual(attachment.fileName, "notes.pdf")
        XCTAssertEqual(attachment.kind, .document)
        XCTAssertTrue(FileManager.default.fileExists(atPath: attachment.fileURL.path))
        // Staged, not referenced: the original is untouched and the copy lives in our own directory.
        XCTAssertNotEqual(attachment.fileURL, source)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(try attachment.loadData().count, 1024)

        attachment.discard()
        XCTAssertFalse(FileManager.default.fileExists(atPath: attachment.fileURL.path))
    }

    /// The check must happen *before* the copy, so rejecting a large file never duplicates it.
    func testRejectsFilesOverTheLimitWithoutCopying() async throws {
        let source = try makeFile(named: "big.pdf", byteCount: 4096)
        let directoryBefore = try contentsOfStore()

        do {
            _ = try await importer.stage(
                source: source,
                isSecurityScoped: false,
                allowedContentTypes: [],
                maximumByteCount: 1024
            )
            XCTFail("expected the oversized file to be rejected")
        } catch let error as LCUIChatAttachmentError {
            XCTAssertEqual(error, .tooLarge(byteCount: 4096, maximum: 1024))
        }

        XCTAssertEqual(try contentsOfStore(), directoryBefore, "nothing should have been copied")
    }

    func testAcceptsAFileExactlyAtTheLimit() async throws {
        let source = try makeFile(named: "exact.pdf", byteCount: 1024)
        let attachment = try await importer.stage(
            source: source,
            isSecurityScoped: false,
            allowedContentTypes: [],
            maximumByteCount: 1024
        )
        XCTAssertEqual(attachment.byteCount, 1024)
    }

    func testRejectsDisallowedContentTypes() async throws {
        let source = try makeFile(named: "notes.pdf", byteCount: 16)
        do {
            _ = try await importer.stage(
                source: source,
                isSecurityScoped: false,
                allowedContentTypes: [.jpeg],
                maximumByteCount: 1024 * 1024
            )
            XCTFail("expected a PDF to be rejected when only JPEG is allowed")
        } catch let error as LCUIChatAttachmentError {
            XCTAssertEqual(error, .unsupportedType(.pdf))
        }
    }

    /// A subtype of an allowed type is allowed: hosts configure `.image`, users pick a PNG.
    func testAcceptsSubtypesOfAllowedContentTypes() async throws {
        let source = try makeFile(named: "shot.png", byteCount: 16)
        let attachment = try await importer.stage(
            source: source,
            isSecurityScoped: false,
            allowedContentTypes: [.image],
            maximumByteCount: 1024 * 1024
        )
        XCTAssertEqual(attachment.kind, .image)
    }

    func testMissingSourceIsReportedAsUnreadable() async throws {
        let missing = scratch.appendingPathComponent("nope.pdf")
        do {
            _ = try await importer.stage(
                source: missing,
                isSecurityScoped: false,
                allowedContentTypes: [],
                maximumByteCount: 1024
            )
            XCTFail("expected a missing file to be rejected")
        } catch let error as LCUIChatAttachmentError {
            XCTAssertEqual(error, .unreadable())
        }
    }

    func testSanitisesTheStagedFileName() async throws {
        // `lastPathComponent` cannot contain a separator, but it can carry quotes and semicolons.
        let source = try makeFile(named: "a\"b;c.pdf", byteCount: 16)
        let attachment = try await importer.stage(
            source: source,
            isSecurityScoped: false,
            allowedContentTypes: [],
            maximumByteCount: 1024 * 1024
        )
        XCTAssertFalse(attachment.fileName.contains("\""))
        XCTAssertFalse(attachment.fileName.contains(";"))
    }

    func testFinishDeletesFilesOverTheLimit() async throws {
        let staged = try LCUIChatAttachmentStore.destination(fileName: "clip.mp4")
        try Data(repeating: 0, count: 4096).write(to: staged)

        do {
            _ = try await importer.finish(
                stagedFile: staged,
                preferredFileName: nil,
                allowedContentTypes: [],
                maximumByteCount: 1024
            )
            XCTFail("expected the oversized staged file to be rejected")
        } catch let error as LCUIChatAttachmentError {
            XCTAssertEqual(error, .tooLarge(byteCount: 4096, maximum: 1024))
        }

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: staged.path),
            "a rejected staged file must not be left behind"
        )
    }

    func testFinishClassifiesVideoFromTheFileItself() async throws {
        let staged = try LCUIChatAttachmentStore.destination(fileName: "clip.mp4")
        try Data(repeating: 0, count: 32).write(to: staged)

        let attachment = try await importer.finish(
            stagedFile: staged,
            preferredFileName: nil,
            allowedContentTypes: [],
            maximumByteCount: 1024 * 1024
        )
        // Regression: library picks were hardcoded to `.image`, so a chosen video was handed to
        // the host as an image and then failed to preview.
        XCTAssertEqual(attachment.kind, .video)
        XCTAssertEqual(attachment.contentType, .mpeg4Movie)
    }

    func testClaimSurvivesDeletionOfTheOriginal() async throws {
        let source = try makeFile(named: "capture.mov", byteCount: 2048)

        let claimed = try LCUIChatAttachmentStore.claim(source)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path), "the move should not leave a duplicate")

        let attachment = try await importer.finish(
            stagedFile: claimed,
            preferredFileName: "capture.mov",
            allowedContentTypes: [],
            maximumByteCount: 1024 * 1024
        )
        XCTAssertEqual(attachment.byteCount, 2048)
        XCTAssertEqual(attachment.fileName, "capture.mov")
        XCTAssertEqual(attachment.kind, .video)
    }

    /// A camera capture is always QuickTime, and `quickTimeMovie` is a sibling of `mpeg4Movie`
    /// rather than a subtype, so a widget that allows only `mp4` would otherwise reject every
    /// recording. The bytes here are not a real movie, so the export cannot succeed — what this
    /// asserts is that the failure is reported and the staged file is not left behind.
    func testUnexportableMovieInADisallowedContainerIsRejectedAndCleanedUp() async throws {
        let staged = try LCUIChatAttachmentStore.destination(fileName: "capture.mov")
        try Data(repeating: 0, count: 32).write(to: staged)

        do {
            _ = try await importer.finish(
                stagedFile: staged,
                preferredFileName: nil,
                allowedContentTypes: [.mpeg4Movie],
                maximumByteCount: 1024 * 1024
            )
            XCTFail("expected a QuickTime file to be rejected when only MPEG-4 is allowed")
        } catch let error as LCUIChatAttachmentError {
            XCTAssertEqual(error, .unsupportedType(.quickTimeMovie))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: staged.path))
    }

    /// The same container in the allowed list needs no rewrite at all.
    func testMovieInAnAllowedContainerIsAcceptedUntouched() async throws {
        let staged = try LCUIChatAttachmentStore.destination(fileName: "capture.mov")
        try Data(repeating: 0, count: 32).write(to: staged)

        let attachment = try await importer.finish(
            stagedFile: staged,
            preferredFileName: "capture.mov",
            allowedContentTypes: [.quickTimeMovie, .mpeg4Movie],
            maximumByteCount: 1024 * 1024
        )
        XCTAssertEqual(attachment.fileURL, staged)
        XCTAssertEqual(attachment.contentType, .quickTimeMovie)
    }

    private func contentsOfStore() throws -> Set<String> {
        let directory = try LCUIChatAttachmentStore.directory()
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        return Set(names)
    }
}
