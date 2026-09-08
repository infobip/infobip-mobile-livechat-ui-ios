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
    private let onSend: (String) -> Void
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
    private let buttonIconSize: CGFloat = 20

    public init(
        isEnabled: Bool = true,
        text: Binding<String>? = nil,
        onSend: @escaping (String) -> Void,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self.isEnabled = isEnabled
        self.externalText = text
        self.onSend = onSend
        self.onAttachmentTapped = onAttachmentTapped
        self.onTextChange = onTextChange
    }

    public init(configuration: LCUIChatComposerConfiguration) {
        self.init(
            isEnabled: configuration.isEnabled,
            text: configuration.text,
            onSend: configuration.onSend,
            onAttachmentTapped: configuration.onAttachmentTapped,
            onTextChange: configuration.onTextChange
        )
    }

    private var isSendEnabled: Bool {
        isEnabled
            && !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isOverLimit
    }
    private var isOverLimit: Bool { text.wrappedValue.count > maximumCharacterCount }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                TextField(settings.texts.sendAMessage, text: text, axis: .vertical)
                    .lineLimit(1...4) // After 4 lines, text will just start scrolling
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .foregroundStyle(colors.primary)
                    .tint(colors.primary)
                    .padding(.horizontal, 4)
                    .onChange(of: text.wrappedValue) { newValue in
                        onTextChange(newValue)
                    }

                HStack(alignment: .bottom, spacing: 8) {
                    if constraints.isAttachmentUploadEnabled {
                        Button(action: onAttachmentTapped) {
                            icons.attachments.addButton
                                .resizable()
                                .scaledToFit()
                                .frame(width: buttonIconSize, height: buttonIconSize)
                                .foregroundStyle(isEnabled ? colors.secondary : theme.secondaryColorDisabled)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Circle().fill(.clear))
                                .clipShape(Circle())
                        }
                        .disabled(!isEnabled)
                        .accessibilityLabel(attTexts.attachments)
                    }

                    Spacer()

                    Button(action: submit) {
                        icons.sendButton
                            .resizable()
                            .scaledToFit()
                            .frame(width: buttonIconSize, height: buttonIconSize)
                            .foregroundStyle(isSendEnabled ? colors.sendButtonTint : theme.sendButtonTintColorDisabled)
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

            if text.wrappedValue.count >= charCounterVisibleThreshold {
                Text("\(text.wrappedValue.count)/\(maximumCharacterCount)")
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
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colors.secondary.opacity(0.12))
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
        onSend(text.wrappedValue)
        // Hosts that own the text via a binding decide themselves when to clear it, so a failed end can keep the draft rather than losing what the user typed.
        if externalText == nil {
            internalText = ""
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

