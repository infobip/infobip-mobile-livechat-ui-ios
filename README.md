# LiveChatUI

SwiftUI UI components for building Infobip Live Chat experiences on iOS: a chat screen shell, a
message composer, an attachment picker, an attachment preview, and error/banner presentation.

This package is deliberately **presentation-only**. It owns no networking, no chat session, and no
widget state — it renders what you give it and calls back when the user does something. Chat
content itself is supplied by the host as a `UIView` (typically a `WKWebView`) that the package
hosts for you.

If you want the full LiveChat solution, please continue reading [here](https://github.com/infobip/mobile-messaging-sdk-ios/wiki/In%E2%80%90app-chat).

## Requirements

| | |
|---|---|
| Deployment target | iOS 15 |
| Views require | **iOS 16** |
| Swift | 5.9+ (built in Swift 5 language mode with complete data-race checking) |

The package temporarily *links* against iOS 15 due to legacy reasons in other dependency, but only offer view in iOS 16, which will soon be the deployment target.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "<repository-url>", from: "latest version")
]
```

### CocoaPods

```ruby
pod 'LiveChatUI', '~> latest version'
```

Note that CocoaPods will cease to be updated at the end of 2026.

## Info.plist keys

The attachment picker uses the camera. Without these keys the app is terminated the moment the user
taps *Take Photo or Video*:

| Key | Needed for |
|---|---|
| `NSCameraUsageDescription` | Taking a photo or video |
| `NSMicrophoneUsageDescription` | Recording a video with sound |

The photo library uses `PhotosPicker`, which runs out of process — no `NSPhotoLibraryUsageDescription`
is required.

## Usage

```swift
import LiveChatUI

@available(iOS 16, *)
struct ChatScreen: View {
    @StateObject private var model: ChatModel

    var body: some View {
        LCUIChatScreenView(
            isComposerEnabled: model.isConnected,
            error: model.fatalError,
            bannerMessage: model.bannerMessage,
            onBannerTapped: model.retry,
            onSend: model.send,
            onAttachmentTapped: { model.isPickingAttachment = true }
        ) {
            LCUIChatWebContentHost(webView: model.webView)
        }
        .lcuiChatSettings(model.settings)
        .sheet(isPresented: $model.isPickingAttachment) {
            LCUIChatAttachmentPickerView(
                onPick: model.upload,
                onError: model.present
            )
        }
    }
}
```

### Theming and copy

Everything configurable lives in a single `LCUIChatSettings` value injected through the
environment:

```swift
.lcuiChatSettings(
    LCUIChatSettings(
        theme: LCUIChatTheme(
            lightPrimaryColor: .black,
            darkPrimaryColor: .white,
            currentColorMode: .light
        ),
        texts: LCUIChatTexts(navigationTitle: Text("Support")),
        icons: LCUIChatIcons(sendButton: Image("send")),
        constraints: LCUIChatConstraints(
            maximumCharacterCount: 2000,
            allowedContentTypes: [.jpeg, .png, .pdf],
            maximumAttachmentByteCount: 10 * 1024 * 1024
        )
    )
)
```

Color customization is intentionally narrow: `lightPrimaryColor`/`darkPrimaryColor` set the single
accent color used per mode (navigation, send button, etc). `secondary` and `background` come from
the fixed `LCUIChatTheme.Colors.light`/`.dark` palettes and aren't independently brandable, and
`sendButtonBackground`/`sendButtonTint` are derived from `primary`/`background` rather than
separate settings. `LCUIChatTheme.Layout(prefersLiquidGlass:)` (default `true`, ignored below
iOS 26) is the other themeable knob.

`currentColorMode: LCUIChatTheme.ColorMode` (`.light`/`.dark`) selects which palette is active, but
it is **not** tied to the system appearance automatically — track appearance yourself (e.g. via
`@Environment(\.colorScheme)`) and re-inject a `LCUIChatTheme` with the matching mode when it
changes.

All user-facing strings are `Text` values you supply — the package's own defaults are English
placeholders. Localize by passing already-localized `Text` from your own bundle.

`LCUIChatConstraints.allowedContentTypes` is applied consistently to all three attachment entry
points, so restricting to images hides the video option in the library picker and the camera alike.
If your configuration arrives as file extensions, use the `allowedFileExtensions:` initializer —
extensions the system cannot resolve to a declared type are dropped rather than silently
mismatching every file the user picks.

### Attachment lifecycle

`LCUIChatAttachment` references a file the package has staged in its own temporary directory; it
does not hold the bytes in memory, so a large video capture costs disk rather than RAM. Read it via
`fileURL` (preferably streaming) or `loadData()`.

**The host owns the file's lifetime.** Call `attachment.discard()` once you have finished uploading
it, and `LCUIChatAttachment.discardAll()` when tearing the chat down, or staged files accumulate in
the app container until the system next clears `tmp`.

Failures are reported through `onError` as `LCUIChatAttachmentError` — oversized files, unreadable
files, disallowed types, and denied camera permission. `error.message(using:)` maps one to the
matching string from your `LCUIChatTexts`.

### Attachment previews

`LCUIChatPreviewAttachment.sourceURL` is the URL used by the preview: images and videos can use a remote URL, while documents must use a local file URL that Quick Look can read. When the host stages a remote document locally, pass its remote address separately as `originalURL` so it remains available if native preview cannot handle the file.

`LCUIChatAttachmentPreview` accepts an optional `onPreviewFailure` callback. When a remote URL is available, it is called with that URL if an image load or video item fails, or when Quick Look reports that a document is not previewable. If the attachment has only a local file URL and no `originalURL`, there is no remote URL to pass and the callback is not invoked. The host can use the callback to offer an alternate viewer, for example:

```swift
LCUIChatAttachmentPreview(
    attachment: LCUIChatPreviewAttachment(
        fileName: "invoice.pdf",
        kind: .document,
        sourceURL: stagedFileURL,
        originalURL: downloadURL
    ),
    onPreviewFailure: { url in
        UIApplication.shared.open(url)
    }
)
```

Quick Look does not report every failure that may occur after rendering starts, so the callback cannot recover from failures the framework does not expose. The host is responsible for staging remote documents and for deciding how to handle the callback (including whether to open the URL externally).

### Custom composer

`LCUIChatScreenView` accepts any composer conforming to `LCUIChatComposing`:

```swift
@available(iOS 16, *)
struct MyComposer: LCUIChatComposing {
    let configuration: LCUIChatComposerConfiguration

    init(configuration: LCUIChatComposerConfiguration) {
        self.configuration = configuration
    }

    var body: some View { /* … */ }
}

LCUIChatScreenView(composer: MyComposer.self, onSend: model.send) { webContent }
```

Pass `LCUIChatComposerConfiguration.text` a binding if you want to own the draft — useful for
restoring what the user typed after a send fails, which the composer's internal state cannot do.

## Development

```sh
# Build and test (iOS only — the package imports UIKit, so `swift build` on macOS will not work)
xcodebuild build -scheme infobip-mobile-livechat-ui-ios -destination 'generic/platform=iOS Simulator'
xcodebuild test  -scheme infobip-mobile-livechat-ui-ios -destination 'platform=iOS Simulator,name=iPhone 17'

# Data-race checking gate — must stay silent
xcrun --sdk iphoneos swiftc -target arm64-apple-ios15.0 -typecheck \
  -module-name LiveChatUI -strict-concurrency=complete $(find Sources -name '*.swift')
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
