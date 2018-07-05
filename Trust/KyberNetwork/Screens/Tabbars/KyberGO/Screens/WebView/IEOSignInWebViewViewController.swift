// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import WebKit

class IEOSignInWebViewViewController: KNBaseViewController, WKUIDelegate, WKScriptMessageHandler {

  fileprivate var webView: WKWebView!
  let userContentController = WKUserContentController()

  override func loadView() {
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = userContentController
    self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
    self.webView.uiDelegate = self
    self.view = self.webView
    userContentController.add(self, name: "userLogin")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let myURL = URL(string: "https://kyber.mangcut.vn/users/sign_in")
    let myRequest = URLRequest(url: myURL!)
    self.webView.load(myRequest)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = navigationAction.request.url else {
      decisionHandler(.allow)
      return
    }

    if url.absoluteString.contains("/login/success") {
      // this means login successful
      decisionHandler(.cancel)
      _ = self.navigationController?.popViewController(animated: false)
    } else {
      decisionHandler(.allow)
    }
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    let dict = message.body as! JSONDictionary
    print("diction: \(dict)")
  }
}
