// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KYCFlowViewEvent {
  case back
}

protocol KYCFlowViewControllerDelegate: class {
  func kycFlowViewController(_ controller: KYCFlowViewController, run event: KYCFlowViewEvent)
}

class KYCFlowViewModel {
  let user: IEOUser

  init(user: IEOUser) { self.user = user }
}

class KYCFlowViewController: KNBaseViewController {

  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var stepView: KNKYCStepView!
  @IBOutlet weak var scrollView: UIScrollView!

  fileprivate var viewModel: KYCFlowViewModel
  weak var delegate: KYCFlowViewControllerDelegate?

  init(viewModel: KYCFlowViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KYCFlowViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupStepView()
    self.setupPersonalInfoView()
  }

  fileprivate func setupStepView() {
    self.navigationTitleLabel.text = "Personal Info".toBeLocalised()
    self.stepView.updateView(with: .personalInfo)
  }

  fileprivate func setupPersonalInfoView() {
    let width = self.view.frame.width
    let height = self.view.frame.height - self.scrollView.frame.minY

    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: width,
      height: height
    )

    let personalInfoVC: KYCPersonalInfoViewController = {
      let viewModel = KYCPersonalInfoViewModel(user: self.viewModel.user)
      let controller = KYCPersonalInfoViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.addChildViewController(personalInfoVC)
    personalInfoVC.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
    self.scrollView.addSubview(personalInfoVC.view)
    personalInfoVC.didMove(toParentViewController: self)

    self.scrollView.contentSize = CGSize(
      width: self.scrollView.frame.width * 4.0,
      height: 1.0
    )
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kycFlowViewController(self, run: .back)
  }
}

extension KYCFlowViewController: KYCPersonalInfoViewControllerDelegate {
  func kycPersonalInfoViewController(_ controller: KYCPersonalInfoViewController, run event: KYCPersonalInfoViewEvent) {
  }
}
