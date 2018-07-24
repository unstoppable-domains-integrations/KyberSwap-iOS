// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNImportWalletViewEvent {
  case back
  case importJSON(json: String, password: String)
  case importPrivateKey(privateKey: String)
  case importSeeds(seeds: [String])
}

protocol KNImportWalletViewControllerDelegate: class {
  func importWalletViewController(_ controller: KNImportWalletViewController, run event: KNImportWalletViewEvent)
}

class KNImportWalletViewController: KNBaseViewController {

  weak var delegate: KNImportWalletViewControllerDelegate?

  fileprivate var isViewSetup: Bool = false
  @IBOutlet weak var buttonsTabBar: UITabBar!
  @IBOutlet var bottomIndicatorViews: [UIView]!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var pageControl: UIPageControl!

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  fileprivate func setupUI() {
    self.setupTabBarView()
    self.setupScrollView()
  }

  fileprivate func setupTabBarView() {
    self.buttonsTabBar.layer.borderWidth = 0.0
    self.buttonsTabBar.clipsToBounds = true

    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18),
      ]
    let jsonItem: UITabBarItem = UITabBarItem(
      title: "JSON",
      image: UIImage(named: "import_json_icon"),
      selectedImage: UIImage(named: "import_json_icon")
    )
    jsonItem.setTitleTextAttributes(attributes, for: .normal)
    jsonItem.setTitleTextAttributes(attributes, for: .selected)
    jsonItem.tag = 0
    let privateKeyItem: UITabBarItem = UITabBarItem(
      title: "Private Key",
      image: UIImage(named: "import_private_key_icon"),
      selectedImage: UIImage(named: "import_private_key_icon")
    )
    privateKeyItem.setTitleTextAttributes(attributes, for: .normal)
    privateKeyItem.setTitleTextAttributes(attributes, for: .selected)
    privateKeyItem.tag = 1
    let seedsItem: UITabBarItem = UITabBarItem(
      title: "Seeds",
      image: UIImage(named: "import_seeds_icon"),
      selectedImage: UIImage(named: "import_seeds_icon")
    )
    seedsItem.setTitleTextAttributes(attributes, for: .normal)
    seedsItem.setTitleTextAttributes(attributes, for: .selected)
    seedsItem.tag = 2
    self.buttonsTabBar.items = [
      jsonItem,
      privateKeyItem,
      seedsItem,
    ]
    self.buttonsTabBar.unselectedItemTintColor = .white
    self.buttonsTabBar.selectedItem = jsonItem
    self.bottomIndicatorViews[0].backgroundColor = UIColor.Kyber.lighterGreen
    self.buttonsTabBar.delegate = self
  }

  fileprivate func setupScrollView() {
    let width: CGFloat = self.view.frame.width
    let height: CGFloat = self.view.frame.height - self.scrollView.frame.minY
    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: width,
      height: height
    )

    let importJSONVC: KNImportJSONViewController = {
      let controller = KNImportJSONViewController()
      controller.delegate = self
      return controller
    }()
    let importPrivateKeyVC: KNImportPrivateKeyViewController = {
      let controller = KNImportPrivateKeyViewController()
      controller.delegate = self
      return controller
    }()
    let importSeedsVC: KNImportSeedsViewController = {
      let controller = KNImportSeedsViewController()
      controller.delegate = self
      return controller
    }()
    let viewControllers = [importJSONVC, importPrivateKeyVC, importSeedsVC]
    self.scrollView.contentSize = CGSize(
      width: CGFloat(viewControllers.count) * width,
      height: height
    )
    self.scrollView.delegate = self
    for id in 0..<viewControllers.count {
      let viewController = viewControllers[id]
      self.addChildViewController(viewController)
      self.scrollView.addSubview(viewController.view)
      let originX: CGFloat = CGFloat(id) * width
      viewController.view.frame = CGRect(
        x: originX,
        y: 0,
        width: width,
        height: height
      )
      viewController.didMove(toParentViewController: self)
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.importWalletViewController(self, run: .back)
  }

  @IBAction func pageControlValueDidChange(_ sender: UIPageControl) {
    self.updateUIWithCurrentPage(sender.currentPage)
  }

  fileprivate func updateUIWithCurrentPage(_ page: Int) {
    self.view.endEditing(true)
    UIView.animate(withDuration: 0.15) {
      self.pageControl.currentPage = page
      self.buttonsTabBar.selectedItem = self.buttonsTabBar.items?.first(where: { $0.tag == page })
      let x = CGFloat(page) * self.scrollView.frame.size.width
      self.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
      self.bottomIndicatorViews.forEach {
        $0.backgroundColor = $0.tag == page ? UIColor.Kyber.lighterGreen : .clear
      }
      self.view.layoutIfNeeded()
    }
  }
}

extension KNImportWalletViewController: UITabBarDelegate {
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    if let id = tabBar.items?.index(of: item) {
      self.updateUIWithCurrentPage(id)
    }
  }
}

extension KNImportWalletViewController: UIScrollViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
    self.updateUIWithCurrentPage(Int(pageNumber))
  }
}

extension KNImportWalletViewController: KNImportJSONViewControllerDelegate {
  func importJSONViewControllerDidPressNext(sender: KNImportJSONViewController, json: String, password: String) {
    self.delegate?.importWalletViewController(
      self,
      run: .importJSON(json: json, password: password)
    )
    let json: JSONDictionary = ["json": json, "password": password]
    KNNotificationUtil.postNotification(for: "notification", object: nil, userInfo: json)
  }
}

extension KNImportWalletViewController: KNImportPrivateKeyViewControllerDelegate {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String) {
    self.delegate?.importWalletViewController(
      self,
      run: .importPrivateKey(privateKey: privateKey)
    )
  }
}

extension KNImportWalletViewController: KNImportSeedsViewControllerDelegate {
  func importSeedsViewControllerDidPressNext(sender: KNImportSeedsViewController, seeds: [String]) {
    self.delegate?.importWalletViewController(self, run: .importSeeds(seeds: seeds))
  }
}
