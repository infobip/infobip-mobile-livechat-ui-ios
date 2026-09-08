//
//  LCUIChatWebContentHost.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import UIKit
import WebKit

@available(iOS 16, *)
public struct LCUIChatWebContentHost<WebView: UIView>: UIViewRepresentable {
    private let webView: WebView
    private let usesLiquidGlassChrome: Bool

    public init(webView: WebView, usesLiquidGlassChrome: Bool = false) {
        self.webView = webView
        self.usesLiquidGlassChrome = usesLiquidGlassChrome
    }

    public func makeUIView(context: Context) -> WebView {
        webView
    }

    public func updateUIView(_ uiView: WebView, context: Context) {
        guard let scrollView = (uiView as? WKWebView)?.scrollView else { return }
        scrollView.contentInsetAdjustmentBehavior = .never
        guard #available(iOS 26, *) else { return }
        scrollView.topEdgeEffect.style = usesLiquidGlassChrome ? .automatic : .hard
        scrollView.bottomEdgeEffect.style = usesLiquidGlassChrome ? .automatic : .hard
    }
}

@available(iOS 16, *)
#Preview {
    LCUIChatWebContentHost(webView: UIView())
}
