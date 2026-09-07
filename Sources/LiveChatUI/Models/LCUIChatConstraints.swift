//
//  LCUIChatConstraints.swift
//  Livechat UI
//
//  Copyright (c) 2016-2026 Infobip Limited
//  Licensed under the Apache License, Version 2.0
//

import SwiftUI
import Photos

public struct LCUIChatConstraints: Sendable {
    public private(set) var charCounterVisibleForLength: UInt
    public private(set) var charCounterVisibleThreshold: UInt
    public private(set) var allowedContentTypes: [String]
    public private(set) var isAttachmentUploadEnabled: Bool
    
    public init (
        charCounterVisibleForLength: UInt = 1024*4, // above 4096, char counter becomes red
        charCounterVisibleThreshold: UInt = 4000, // above 4000, char counter becomes visible as light gray
        allowedContentTypes: [String] = ["mp4", "jpeg", "jpg"],
        isAttachmentUploadEnabled: Bool = true
       ) {
           self.charCounterVisibleForLength = charCounterVisibleForLength
           self.charCounterVisibleThreshold = charCounterVisibleThreshold
           self.allowedContentTypes = allowedContentTypes
           self.isAttachmentUploadEnabled = isAttachmentUploadEnabled
    }
    
    public var isCameraNeededForAllowedContentTypes: Bool {
        let videoExtensions: Set<String> = ["mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "mpeg", "mpg", "m4v", "3gp", "ogv", "ts", "vob", "rm", "rmvb", "divx", "asf", "m2ts", "srt"]

        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp", "svg", "ico", "heic", "heif", "raw", "cr2", "nef", "arw", "dng", "psd"]

        let allowedVideoTypes = Set(allowedContentTypes).intersection(videoExtensions)
        let alloweImagesTypes =  Set(allowedContentTypes).intersection(imageExtensions)
        return !(allowedVideoTypes.isEmpty && alloweImagesTypes.isEmpty)
    }
    
    public var allowedMimeTypes: [UTType] {
        var contentTypes: [UTType] = []
        for typeExtension in allowedContentTypes {
            if let uType = UTType(filenameExtension: typeExtension) {
                contentTypes.append(uType)
            }
        }
        return contentTypes
    }

}
