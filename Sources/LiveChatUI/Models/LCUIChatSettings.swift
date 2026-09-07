
//
//  LCUIChatSettings.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI

public struct LCUIChatSettings: Sendable {
    public private(set) var theme: LCUIChatTheme
    public private(set) var texts: LCUIChatTexts
    public private(set) var icons: LCUIChatIcons
    public private(set) var constraints: LCUIChatConstraints
    
    public init(
        theme: LCUIChatTheme = .default,
        texts: LCUIChatTexts = LCUIChatTexts(),
        icons: LCUIChatIcons = LCUIChatIcons(),
        constraints: LCUIChatConstraints = LCUIChatConstraints()
    ) {
        self.theme = theme
        self.texts = texts
        self.icons = icons
        self.constraints = constraints
    }
}
