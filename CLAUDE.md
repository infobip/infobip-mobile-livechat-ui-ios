# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

LiveChatUI is a Swift Package providing SwiftUI UI components for building Infobip Live Chat experiences on iOS — chat screen shell, message composer, attachment picker/preview, and error/banner presentation. It is deliberately presentation-only: no networking, no chat session, no widget state. The host app owns all of that and supplies content (typically a `WKWebView`) and drives the views via closures/bindings/injected config.

Deployment target is iOS 15 (so integrating apps don't need to raise their minimum target), but all exposed views are `@available(iOS 16, *)` and must be gated by `if #available(iOS 16, *)`. Some internal chrome logic further branches on iOS 26 ("liquid glass").

## Build & test

This package imports UIKit, so plain `swift build`/`swift test` will NOT work on macOS — always build/test for iOS:

```sh
# Build and test
xcodebuild build -scheme infobip-mobile-livechat-ui-ios -destination 'generic/platform=iOS Simulator'
xcodebuild test  -scheme infobip-mobile-livechat-ui-ios -destination 'platform=iOS Simulator,name=iPhone 17'

# Run a single test
xcodebuild test -scheme infobip-mobile-livechat-ui-ios \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:LiveChatUITests/LCUIChatConstraintsTests/testDefaultsAllowImagesAndVideos

# Strict-concurrency (data-race) gate — must stay silent
xcrun --sdk iphoneos swiftc -target arm64-apple-ios15.0 -typecheck \
  -module-name LiveChatUI -strict-concurrency=complete $(find Sources -name '*.swift')
```

No Fastfile, Makefile, SwiftLint config, or `Example/` app exists in this repo. Tests use XCTest (not Swift Testing) under `Tests/LiveChatUITests/`.

## Architecture

Pure SwiftUI presentation-component library — not MVVM/MVC. No ViewModels; the host owns state and drives views via closures/bindings.

- **`Sources/LiveChatUI/Models/`** — config/data value types, mostly `Sendable`:
  - `LCUIChatSettings` is the single environment-injected root config, bundling `theme: LCUIChatTheme`, `texts: LCUIChatTexts`, `icons: LCUIChatIcons`, `constraints: LCUIChatConstraints`. Injected via `.lcuiChatSettings(...)` and read via `@Environment(\.lcuiChatSettings)` throughout views. This is the primary DI mechanism — check here first when threading new config through the package.
  - `LCUIChatDataTypes.swift` — core domain types: `LCUIChatAttachment` (holds a `fileURL`, not bytes; `loadData()`, `discard()`, static `discardAll()`), `LCUIChatAttachmentKind`, `LCUIChatAttachmentError`, `LCUIChatError`.
  - `LCUIChatAttachmentStore.swift` — `enum LCUIChatAttachmentStore` (staging directory, filename sanitization, content-type resolution) and `actor LCUIChatAttachmentImporter` (async off-main-actor staging/validation, including remuxing camera QuickTime movies via `AVAssetExportSession`).
  - `LCUIChatConstraints.swift` — max chars, allowed content types, attachment size limits, camera/photo-library capability derivation.

- **`Sources/LiveChatUI/Views/`**:
  - `LCUIChatScreenView` — main entry-point container (generic over `Composer: LCUIChatComposing`); composes web content, error banner/full-screen error, and the composer.
  - `LCUIChatComposing` — the extensibility seam: a `@MainActor` protocol (`init(configuration: LCUIChatComposerConfiguration)`) letting hosts supply a fully custom message composer. `LCUIChatComposerView` is the default implementation.
  - `LCUIChatAttachmentPickerView` — camera/photo-library/document picker sheet; wires `UIImagePickerController` via `UIViewControllerRepresentable` + delegate `Coordinator`, and `PhotosPicker`/`fileImporter`. Uses `.task(id:)` tied to picker-source state for cancellation-safe async staging, delegating file work to `LCUIChatAttachmentImporter`.
  - `LCUIChatWebContentHost` — `UIViewRepresentable` bridge hosting an arbitrary host-supplied `UIView` (typically `WKWebView`); handles SwiftUI layout/chrome only (scroll insets, liquid-glass edge effects) — it owns no JS bridge or web content, that stays in the host app.
  - `LCUIChatAttachmentPreview`, `LCUIChatErrorBannerView`, `LCUIChatFullScreenErrorView` — presentation-only, driven off `LCUIChatError`/`Text` values from the host.

- **Patterns to follow when extending**:
  - Config additions go through `LCUIChatSettings` + environment, not new init params scattered across views.
  - New pluggable behavior (like the composer) should follow the `LCUIChatComposing`-style protocol/generic pattern rather than subclassing or flags.
  - Async work in Models/ uses actors and `async throws`; async work in Views uses `.task(id:)` for cancellation safety, not manual Task handles.
  - All public API is closure-driven (`onSend`, `onAttachmentTapped`, etc.) — no Combine publishers on the public surface.
  - New attachment-related state should reference files via `fileURL` (staged via `LCUIChatAttachmentStore`), not hold raw `Data` in memory; remember to call `discard()`/`discardAll()` where the lifecycle requires it.
  - New public views must be gated `@available(iOS 16, *)`; anything targeting iOS 26 liquid-glass behavior should follow the existing `#available(iOS 26, *)` branching convention.
  - Nearly everything is `Sendable`; keep new types `Sendable`-compatible since strict concurrency checking is enforced (Swift 5 language mode + `StrictConcurrency`/`InferSendableFromCaptures` upcoming features, verified by the standalone `xcrun -strict-concurrency=complete` gate above).
