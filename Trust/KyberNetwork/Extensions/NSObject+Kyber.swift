// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwiftMessages

extension NSObject {
  func showWarningTopBannerMessage(with title: String = "", message: String = "", time: TimeInterval = 1.5) {
    self.showTopBannerView(with: title, message: message, theme: .warning, time: time)
  }

  func showSuccessTopBannerMessage(with title: String = "", message: String = "", time: TimeInterval = 1.5) {
    self.showTopBannerView(with: title, message: message, theme: .success, time: time)
  }

  func showErrorTopBannerMessage(with title: String = "", message: String = "", time: TimeInterval = 1.5) {
    self.showTopBannerView(with: title, message: message, theme: .error, time: time)
  }

  func showTopBannerView(with title: String = "", message: String = "", theme: Theme, layout: MessageView.Layout = .cardView, time: TimeInterval = 1.5) {
    let view: MessageView = {
      let view = MessageView.viewFromNib(layout: layout)
      view.configureTheme(backgroundColor: UIColor.white, foregroundColor: UIColor.black.withAlphaComponent(0.6), iconImage: nil, iconText: nil)
      view.configureDropShadow()
      view.button?.isHidden = true
      if theme == .success {
        let iconText = ""//["😁", "😄", "😆", "😉", "😎", "😍"].sm_random()!
        view.configureContent(title: title, body: message, iconText: iconText)
      } else {
        let iconText = ""//["🤔", "😳", "🙄", "😶", "😰", "😢", "😥"].sm_random()!
        view.configureContent(title: title, body: message, iconText: iconText)
      }
      return view
    }()
    let config: SwiftMessages.Config = {
      var config = SwiftMessages.Config()
      config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
      config.duration = .seconds(seconds: time)
      config.dimMode = .gray(interactive: true)
      config.interactiveHide = true
      config.preferredStatusBarStyle = .lightContent
      return config
    }()
    SwiftMessages.show(config: config, view: view)
  }
}
