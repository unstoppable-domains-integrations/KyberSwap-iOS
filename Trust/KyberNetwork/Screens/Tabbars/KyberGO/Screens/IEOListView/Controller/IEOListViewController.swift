// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import SafariServices

enum IEOListViewEvent {
  case dismiss
  case buy(object: IEOObject)
}

protocol IEOListViewControllerDelegate: class {
  func ieoListViewController(_ controller: IEOListViewController, run event: IEOListViewEvent)
}

class IEOListViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!

  weak var delegate: IEOListViewControllerDelegate?
  fileprivate var viewModel: IEOListViewModel
  fileprivate var controllers: [KGOIEODetailsViewController] = []

  init(viewModel: IEOListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: IEOListViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

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
    self.titleLabel.text = self.viewModel.title
    let width: CGFloat = self.view.frame.width - 30.0
    let height: CGFloat = self.view.frame.height - self.scrollView.frame.minY
    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: self.view.frame.width,
      height: height
    )
    var padding: CGFloat = 15.0
    self.controllers = []
    for object in self.viewModel.objects {
      let viewModel = KGOIEODetailsViewModel(object: object, isFull: false)
      let controller = KGOIEODetailsViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.controllers.append(controller)
      let frame = CGRect(x: padding, y: 0, width: width, height: height)
      controller.view.frame = frame
      self.addChildViewController(controller)
      controller.willMove(toParentViewController: self)
      self.scrollView.addSubview(controller.view)
      padding += width + 30.0
    }
    self.scrollView.contentSize = CGSize(
      width: self.scrollView.frame.width * CGFloat(self.viewModel.objects.count),
      height: 1.0
    )
    if let id = self.viewModel.objects.index(of: self.viewModel.curObject) {
      let rect = CGRect(
        x: CGFloat(id) * self.scrollView.frame.width,
        y: 0,
        width: self.scrollView.frame.width,
        height: height
      )
      self.scrollView.scrollRectToVisible(rect, animated: false)
    }
    self.automaticallyAdjustsScrollViewInsets = false
  }

  func coordinatorDidUpdateProgress() {
    self.controllers.forEach { $0.coordinatorDidUpdateProgress() }
    self.view.layoutIfNeeded()
  }

  func coordinatorDidUpdateRate(_ rate: BigInt, object: IEOObject) {
    guard let controller = self.controllers.first(where: { $0.viewModel.object.id == object.id }) else { return }
    controller.coordinatorDidUpdateRate(rate, object: object)
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.delegate?.ieoListViewController(self, run: .dismiss)
  }
}

extension IEOListViewController: KGOIEODetailsViewControllerDelegate {
  func ieoDetailsViewControllerDidPressBuy(for object: IEOObject, sender: KGOIEODetailsViewController) {
    self.delegate?.ieoListViewController(self, run: .buy(object: object))
  }

  func ieoDetailsViewControllerDidPressWhitePaper(for object: IEOObject, sender: KGOIEODetailsViewController) {
    let urlString: String = {
      for id in 0..<object.customInfoFields.count {
        if object.customInfoFields[id].lowercased() == "whitepaper" {
          return object.customInfoValues[id]
        }
      }
      return ""
    }()
    guard let url = URL(string: urlString) else { return }
    let safariController = SFSafariViewController(url: url)
    self.present(safariController, animated: true, completion: nil)
  }
}
