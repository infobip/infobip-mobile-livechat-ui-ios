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

    private let isEnabled: Bool
    private let onSend: (String) -> Void
    private let onAttachmentTapped: () -> Void
    private let onTextChange: (String) -> Void
    private var maxCharacterCount: UInt {
        settings.constraints.charCounterVisibleForLength
    }
    private var charCounterVisibleThreshold: UInt {
        settings.constraints.charCounterVisibleThreshold
    }

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    private let buttonSize: CGFloat = 44
    private let sendIconSize: CGFloat = 18
    private let attachmentIconSize: CGFloat = 24

    public init(
        isEnabled: Bool = true,
        showsAttachmentButton: Bool = true,
        onSend: @escaping (String) -> Void,
        onAttachmentTapped: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        self.isEnabled = isEnabled
        self.onSend = onSend
        self.onAttachmentTapped = onAttachmentTapped
        self.onTextChange = onTextChange
    }

    public init(configuration: LCUIChatComposerConfiguration) {
        self.init(
            isEnabled: configuration.isEnabled,
            onSend: configuration.onSend,
            onAttachmentTapped: configuration.onAttachmentTapped,
            onTextChange: configuration.onTextChange
        )
    }

    private var isSendEnabled: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= maxCharacterCount
    }
    private var isOverLimit: Bool { text.count > maxCharacterCount }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                TextField(settings.texts.sendAMessage, text: $text, axis: .vertical)
                    .lineLimit(1...4) // After 4 lines, text will just start scrolling
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .foregroundStyle(settings.theme.primaryColor)
                    .tint(settings.theme.primaryColor)
                    .padding(.horizontal, 4)
                    .onChange(of: text) { newValue in
                        onTextChange(newValue)
                    }

                HStack(alignment: .bottom, spacing: 8) {
                    if settings.constraints.isAttachmentUploadEnabled {
                        Button(action: onAttachmentTapped) {
                            settings.icons.addAttachmentButton
                                .resizable()
                                .scaledToFit()
                                .frame(width: attachmentIconSize, height: attachmentIconSize)
                                .foregroundStyle(isEnabled ? settings.theme.secondaryColor : settings.theme.secondaryColorDisabled)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Circle().fill(.clear))
                                .clipShape(Circle())
                        }
                        .disabled(!isEnabled)
                    }

                    Spacer()

                    Button(action: submit) {
                        settings.icons.sendButton
                            .resizable()
                            .scaledToFit()
                            .frame(width: sendIconSize, height: sendIconSize)
                            .foregroundStyle(isSendEnabled ? settings.theme.sendButtonTintColor : settings.theme.sendButtonTintColorDisabled)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(sendButtonBackground)
                            .clipShape(Circle())
                    }
                    .disabled(!isSendEnabled)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(composerContainerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            if text.count >= charCounterVisibleThreshold {
                Text("\(text.count)/\(maxCharacterCount)")
                    .font(.caption2)
                    .foregroundStyle(isOverLimit ? Color.red : settings.theme.secondaryColor)
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
        if #available(iOS 26, *), settings.theme.prefersLiquidGlass {
            Color.clear
        } else {
            settings.theme.backgroundColor
        }
    }

    @ViewBuilder
    private var composerContainerBackground: some View {
        if #available(iOS 26, *), settings.theme.prefersLiquidGlass {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(settings.theme.secondaryColor.opacity(0.12))
        }
    }

    @ViewBuilder
    private var sendButtonBackground: some View {
        if #available(iOS 26, *), settings.theme.prefersLiquidGlass {
            Circle()
                .fill(.clear)
                .glassEffect(
                    .regular.tint(isSendEnabled ? settings.theme.sendButtonBackgroundColor : settings.theme.sendButtonBackgroundColorDisabled),
                    in: Circle()
                )
        } else {
            Circle()
                .fill(isSendEnabled ? settings.theme.sendButtonBackgroundColor : settings.theme.sendButtonBackgroundColorDisabled)
        }
    }

    private func submit() {
        guard isSendEnabled else { return }
        onSend(text)
        text = ""
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

