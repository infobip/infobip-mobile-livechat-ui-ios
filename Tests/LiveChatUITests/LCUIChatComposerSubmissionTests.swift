//
//  LCUIChatComposerSubmissionTests.swift
//  LiveChatUI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import AVFoundation
import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import LiveChatUI

@available(iOS 16, *)
@MainActor
final class LCUIChatComposerSubmissionTests: XCTestCase {
    private final class DraftBox {
        var text: String
        var attachment: LCUIChatAttachment?

        init(text: String, attachment: LCUIChatAttachment?) {
            self.text = text
            self.attachment = attachment
        }
    }

    private func attachment() -> LCUIChatAttachment {
        LCUIChatAttachment(
            fileName: "invoice.pdf",
            fileURL: URL(fileURLWithPath: "/tmp/invoice.pdf"),
            byteCount: 10,
            contentType: .pdf,
            kind: .document
        )
    }

    func testAttachmentCanSendWithoutCaptionButRequiresHandlerAndRespectsLimit() {
        let picked = attachment()
        XCTAssertTrue(LCUIChatComposerSubmission.canSend(
            text: "", attachment: picked, isEnabled: true,
            maximumCharacterCount: 5, hasAttachmentHandler: true
        ))
        XCTAssertFalse(LCUIChatComposerSubmission.canSend(
            text: "", attachment: picked, isEnabled: true,
            maximumCharacterCount: 5, hasAttachmentHandler: false
        ))
        XCTAssertFalse(LCUIChatComposerSubmission.canSend(
            text: "123456", attachment: picked, isEnabled: true,
            maximumCharacterCount: 5, hasAttachmentHandler: true
        ))
        XCTAssertFalse(LCUIChatComposerSubmission.canSend(
            text: "", attachment: picked, isEnabled: false,
            maximumCharacterCount: 5, hasAttachmentHandler: true
        ))
    }

    func testAttachmentSendPassesCaptionAndClearsDraftWithoutSendingTextSeparately() {
        let picked = attachment()
        let draft = DraftBox(text: "Please review", attachment: picked)
        var sentCaption: String?
        var sentAttachment: LCUIChatAttachment?
        var textSendCount = 0

        LCUIChatComposerSubmission.perform(
            text: Binding(get: { draft.text }, set: { draft.text = $0 }),
            attachment: Binding(get: { draft.attachment }, set: { draft.attachment = $0 }),
            onSend: { _ in textSendCount += 1 },
            onSendAttachment: { caption, attachment in
                sentCaption = caption
                sentAttachment = attachment
            }
        )

        XCTAssertEqual(sentCaption, "Please review")
        XCTAssertEqual(sentAttachment, picked)
        XCTAssertNil(draft.attachment)
        XCTAssertEqual(draft.text, "")
        XCTAssertEqual(textSendCount, 0)
    }

    func testAttachmentWithoutHandlerIsNotSentThroughTextCallback() {
        let picked = attachment()
        let draft = DraftBox(text: "Caption", attachment: picked)
        var textSendCount = 0

        LCUIChatComposerSubmission.perform(
            text: Binding(get: { draft.text }, set: { draft.text = $0 }),
            attachment: Binding(get: { draft.attachment }, set: { draft.attachment = $0 }),
            onSend: { _ in textSendCount += 1 },
            onSendAttachment: nil
        )

        XCTAssertEqual(textSendCount, 0)
        XCTAssertEqual(draft.text, "Caption")
        XCTAssertEqual(draft.attachment, picked)
    }

    func testEmptyCaptionIsPassedToAttachmentHandler() {
        let draft = DraftBox(text: "", attachment: attachment())
        var sentCaption: String?

        LCUIChatComposerSubmission.perform(
            text: Binding(get: { draft.text }, set: { draft.text = $0 }),
            attachment: Binding(get: { draft.attachment }, set: { draft.attachment = $0 }),
            onSend: { _ in XCTFail("Text callback must not run") },
            onSendAttachment: { caption, _ in sentCaption = caption }
        )

        XCTAssertEqual(sentCaption, "")
        XCTAssertNil(draft.attachment)
    }

    #if DEBUG
    func testPreviewMediaFilesHaveReadableThumbnails() async {
        for kind in [LCUIChatAttachmentKind.image, .video] {
            guard let picked = await LCUIChatComposerPreviewFile.makeAttachment(kind: kind) else {
                XCTFail("Could not create \(kind) preview file")
                continue
            }
            defer { picked.discard() }
            if kind == .image {
                XCTAssertNotNil(UIImage(contentsOfFile: picked.fileURL.path))
            } else {
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: picked.fileURL))
                XCTAssertNotNil(try? generator.copyCGImage(at: .zero, actualTime: nil))
            }
        }
    }
    #endif
}
