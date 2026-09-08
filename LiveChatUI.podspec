Pod::Spec.new do |s|
  s.name             = 'LiveChatUI'
  s.version          = '0.1.0'
  s.summary          = 'UI components for Infobip Live Chat.'
  s.description      = <<-DESC
LiveChatUI provides SwiftUI-based UI components for building Infobip Live Chat
experiences on iOS.
  DESC

  s.homepage         = 'https://git.ib-ci.com/scm/cma/infobip-mobile-livechat-ui-ios.git'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'Francisco Fortes' => 'francisco.fortes@infobip.com' }
  s.source           = { :git => 'https://git.ib-ci.com/scm/cma/infobip-mobile-livechat-ui-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.9'

  s.source_files     = 'Sources/LiveChatUI/**/*.swift'

  s.frameworks       = 'Foundation', 'SwiftUI', 'UIKit', 'AVKit', 'Photos', 'PhotosUI', 'QuickLook', 'WebKit', 'UniformTypeIdentifiers'
end
