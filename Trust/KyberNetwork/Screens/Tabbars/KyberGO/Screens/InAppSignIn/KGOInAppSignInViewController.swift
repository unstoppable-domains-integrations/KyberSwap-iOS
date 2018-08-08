// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import WebKit

class KGOInAppSignInViewController: KNBaseViewController {

  fileprivate let url: URL

  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var webView: UIWebView!

  init(with url: URL) {
    self.url = url
    super.init(nibName: KGOInAppSignInViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.webView.loadRequest(URLRequest(url: self.url))
    self.webView.delegate = self
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension KGOInAppSignInViewController: UIWebViewDelegate {
  func webViewDidStartLoad(_ webView: UIWebView) {
    self.displayLoading()
  }

  func webViewDidFinishLoad(_ webView: UIWebView) {
    self.hideLoading()
  }

  func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    return true
  }
}
