//
//  LCUIChatVideoPreviewStateTests.swift
//  LiveChatUI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import AVFoundation
import Combine
import XCTest
@testable import LiveChatUI

@MainActor
final class LCUIChatVideoPreviewStateTests: XCTestCase {
    func testPlaybackFailureNotificationMarksCurrentItemFailed() async {
        let state = LCUIChatVideoPreviewState()
        let item = AVPlayerItem(asset: AVMutableComposition())
        state.start(item: item)
        let failure = expectation(description: "Playback failure observed")
        let observation = state.$failed.dropFirst().sink { failed in
            if failed { failure.fulfill() }
        }

        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: item)

        await fulfillment(of: [failure], timeout: 2)
        XCTAssertTrue(state.failed)
        state.stop()
        withExtendedLifetime(observation) {}
    }

    func testStoppedItemCannotFailTheNextPreview() async {
        let state = LCUIChatVideoPreviewState()
        let oldItem = AVPlayerItem(asset: AVMutableComposition())
        let newItem = AVPlayerItem(asset: AVMutableComposition())
        state.start(item: oldItem)
        state.stop()
        state.start(item: newItem)
        let unexpectedFailure = expectation(description: "Old item must not fail new preview")
        unexpectedFailure.isInverted = true
        let observation = state.$failed.dropFirst().sink { failed in
            if failed { unexpectedFailure.fulfill() }
        }

        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: oldItem)

        await fulfillment(of: [unexpectedFailure], timeout: 0.2)
        XCTAssertFalse(state.failed)
        state.stop()
        withExtendedLifetime(observation) {}
    }
}
