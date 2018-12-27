// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import WebKit

class KGOInAppSignInViewController: KNBaseViewController {

  fileprivate let url: URL
  fileprivate let isSignIn: Bool

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var webView: UIWebView!

  init(with url: URL, isSignIn: Bool) {
    self.url = url
    self.isSignIn = isSignIn
    super.init(nibName: KGOInAppSignInViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = self.isSignIn ? NSLocalizedString("sign.in", value: "Sign In", comment: "") : NSLocalizedString("sign.up", value: "Sign Up", comment: "")
    self.navTitleLabel.addLetterSpacing()
    self.webView.loadRequest(URLRequest(url: self.url))
    self.webView.delegate = self
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerView.removeSublayer(at: 0)
    self.headerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    if self.webView.canGoBack {
      self.webView.goBack()
    } else {
      self.navigationController?.popViewController(animated: true)
    }
  }
}

extension KGOInAppSignInViewController: UIWebViewDelegate {
  func webViewDidStartLoad(_ webView: UIWebView) {
    self.displayLoading(text: "\(NSLocalizedString("loading", value: "Loading", comment: ""))...", animated: true)
  }

  func webViewDidFinishLoad(_ webView: UIWebView) {
    self.hideLoading()
  }

  func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    return true
  }

  func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
    self.hideLoading()
  }
}
