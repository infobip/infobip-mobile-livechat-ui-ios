//
//  LCUIChatComposerView.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

@available(iOS 16, *)
public struct LCUIChatComposerView: LCUIChatComposing {
    @Environment(\.lcuiChatSettings) private var settings

    private var theme: LCUIChatTheme { settings.theme }
    private var colors: LCUIChatTheme.Colors { theme.colors }
    private var layout: LCUIChatTheme.Layout { theme.layout }
    private var icons: LCUIChatIcons { settings.icons }
    private var constraints: LCUIChatConstraints { settings.constraints }
    private var attTexts: LCUIChatTexts.Attachments { settings.texts.attachments }

    private let isEnabled: Bool
    private let externalText: Binding<String>?
    private let attachment: Binding<LCUIChatAttachment?>?
    private let onSend: (String) -> Void
    private let onSendAttachment: ((String, LCUIChatAttachment) -> Void)?
    private let onAttachmentTapped: () -> Void
    private let onTextChange: (String) -> Void
    private var maximumCharacterCount: UInt {
        constraints.maximumCharacterCount
    }
    private var charCounterVisibleThreshold: UInt {
        constraints.charCounterVisibleThreshold
    }

    @State private var internalText: String = ""
    @FocusState private var isFocused: Bool

    /// The host's binding when it supplied one, otherwise the composer's own state.
    private var text: Binding<String> {
        externalText ?? $internalText
    }

    private let buttonSize: CGFloat = 44
    private let buttonIconSize: CGFloat = 22

    public init(
        isEnabled: Bool = true,
        text: Binding<String>? = nil,
        attachment: Binding<LCUIChatAttachment?>? = nil,
        onSend: @escaping (String) -> Void,
        onSendAttachment: ((String, LCUIChatAttachment) -> Void)? = nil,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self.isEnabled = isEnabled
        self.externalText = text
        self.attachment = attachment
        self.onSend = onSend
        self.onSendAttachment = onSendAttachment
        self.onAttachmentTapped = onAttachmentTapped
        self.onTextChange = onTextChange
    }

    public init(configuration: LCUIChatComposerConfiguration) {
        self.init(
            isEnabled: configuration.isEnabled,
            text: configuration.text,
            attachment: configuration.attachment,
            onSend: configuration.onSend,
            onSendAttachment: configuration.onSendAttachment,
            onAttachmentTapped: configuration.onAttachmentTapped,
            onTextChange: configuration.onTextChange
        )
    }

    private var selectedAttachment: LCUIChatAttachment? { attachment?.wrappedValue }
    private var canPickAttachment: Bool { isEnabled && selectedAttachment == nil }

    private var isSendEnabled: Bool {
        LCUIChatComposerSubmission.canSend(
            text: text.wrappedValue,
            attachment: selectedAttachment,
            isEnabled: isEnabled,
            maximumCharacterCount: maximumCharacterCount,
            hasAttachmentHandler: onSendAttachment != nil
        )
    }
    private var characterCount: UInt { UInt(text.wrappedValue.count) }
    private var isOverLimit: Bool { characterCount > maximumCharacterCount }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                if let selectedAttachment {
                    LCUIChatComposerAttachmentThumbnail(attachment: selectedAttachment) {
                        attachment?.wrappedValue = nil
                        selectedAttachment.discard()
                    }
                    .id(selectedAttachment.id)
                    .padding(.bottom, 4)
                }

                TextField(settings.texts.sendAMessage, text: text, axis: .vertical)
                    .lineLimit(1...4) // After 4 lines, text will just start scrolling
                    .multilineTextAlignment(.leading)
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .foregroundStyle(colors.secondary)
                    .tint(colors.secondary)
                    .padding(.horizontal, 4)
                    .onChange(of: text.wrappedValue) { newValue in
                        onTextChange(newValue)
                    }

                HStack(alignment: .bottom, spacing: 8) {
                    if constraints.isAttachmentUploadEnabled {
                        Button(action: onAttachmentTapped) {
                            icons.addButton
                                .resizable()
                                .scaledToFit()
                                .frame(width: buttonIconSize, height: buttonIconSize)
                                .foregroundStyle(canPickAttachment ? colors.secondary : theme.secondaryColorDisabled)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Circle().fill(.clear))
                                .clipShape(Circle())
                        }
                        .disabled(!canPickAttachment)
                        .accessibilityLabel(attTexts.attachments)
                    }

                    Spacer()

                    Button(action: submit) {
                        icons.sendButton
                            .resizable()
                            .scaledToFit()
                            .flipsForRightToLeftLayoutDirection(true)
                            .frame(width: buttonIconSize, height: buttonIconSize)
                            .foregroundStyle(isSendEnabled ? theme.activeSendButtonTintColor : theme.sendButtonTintColorDisabled)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(sendButtonBackground)
                            .clipShape(Circle())
                    }
                    .disabled(!isSendEnabled)
                    .accessibilityLabel(settings.texts.send)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(composerContainerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            if characterCount >= charCounterVisibleThreshold {
                Text("\(characterCount)/\(maximumCharacterCount)")
                    .font(.caption2)
                    .foregroundStyle(isOverLimit ? Color.red : colors.secondary)
                    .padding(.top, 6)
                    .padding(.trailing, 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(outerBackground)
    }

    @ViewBuilder
    private var outerBackground: some View {
        if #available(iOS 26, *), layout.prefersLiquidGlass {
            Color.clear
        } else {
            colors.background
        }
    }

    @ViewBuilder
    private var composerContainerBackground: some View {
        if #available(iOS 26, *), layout.prefersLiquidGlass {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .glassEffect(
                    theme.currentColorMode == .dark
                        ? .regular.tint(colors.background.opacity(0.85))
                        : .regular,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colors.background.opacity(0.05))
        }
    }

    @ViewBuilder
    private var sendButtonBackground: some View {
        if #available(iOS 26, *), layout.prefersLiquidGlass {
            Circle()
                .fill(.clear)
                .glassEffect(
                    .regular.tint(isSendEnabled ? colors.sendButtonBackground : theme.sendButtonBackgroundColorDisabled),
                    in: Circle()
                )
        } else {
            Circle()
                .fill(isSendEnabled ? colors.sendButtonBackground : theme.sendButtonBackgroundColorDisabled)
        }
    }

    private func submit() {
        guard isSendEnabled else { return }
        LCUIChatComposerSubmission.perform(
            text: text,
            attachment: attachment,
            onSend: onSend,
            onSendAttachment: onSendAttachment
        )
    }
}

@available(iOS 16, *)
enum LCUIChatComposerSubmission {
    static func canSend(
        text: String,
        attachment: LCUIChatAttachment?,
        isEnabled: Bool,
        maximumCharacterCount: UInt,
        hasAttachmentHandler: Bool
    ) -> Bool {
        guard isEnabled, UInt(text.count) <= maximumCharacterCount else { return false }
        if attachment != nil { return hasAttachmentHandler }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func perform(
        text: Binding<String>,
        attachment: Binding<LCUIChatAttachment?>?,
        onSend: (String) -> Void,
        onSendAttachment: ((String, LCUIChatAttachment) -> Void)?
    ) {
        let message = text.wrappedValue
        if let picked = attachment?.wrappedValue {
            guard let onSendAttachment else { return }
            attachment?.wrappedValue = nil
            text.wrappedValue = ""
            onSendAttachment(message, picked)
        } else {
            onSend(message)
            text.wrappedValue = ""
        }
    }
}

@available(iOS 16, *)
#Preview("Enabled") {
    LCUIChatComposerView(
        onSend: { _ in },
        onAttachmentTapped: {}
    )
    .lcuiChatSettings(.init())
}

@available(iOS 16, *)
#Preview("Disabled") {
    LCUIChatComposerView(
        isEnabled: false,
        onSend: { _ in }
    )
    .lcuiChatSettings(.init())
}

private var darkTheme: LCUIChatTheme {
    LCUIChatTheme(currentColorMode: .dark)
}

@available(iOS 16, *)
#Preview("Dark") {
    VStack{
        Spacer()
        LCUIChatComposerView(
            isEnabled: true,
            onSend: { _ in }
        )
        .lcuiChatSettings(.init(theme: darkTheme))
    }
    .background(.black)
}
