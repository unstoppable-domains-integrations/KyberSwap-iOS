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
  var stepState: KNKYCStepViewState

  init(user: IEOUser) {
    self.user = user
    self.stepState = .personalInfo
  }

  func updateStepState(_ step: KNKYCStepViewState) {
    self.stepState = step
  }
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
    self.stepView.updateView(with: self.viewModel.stepState)
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

    let identityVC: KYCIdentityInfoViewController = {
      let viewModel = KYCIdentityInfoViewModel()
      let controller = KYCIdentityInfoViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.addChildViewController(identityVC)
    identityVC.view.frame = CGRect(x: width, y: 0, width: width, height: height)
    self.scrollView.addSubview(identityVC.view)
    identityVC.didMove(toParentViewController: self)

    self.scrollView.contentSize = CGSize(
      width: self.scrollView.frame.width * 2.0,
      height: 1.0
    )
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    if self.viewModel.stepState != .personalInfo {
      let newState: KNKYCStepViewState = {
        switch self.viewModel.stepState {
        case .personalInfo:
          return .personalInfo
        default:
          return KNKYCStepViewState(rawValue: self.viewModel.stepState.rawValue - 1) ?? .personalInfo
        }
      }()
      self.updateViewState(newState: newState)
    } else {
      self.delegate?.kycFlowViewController(self, run: .back)
    }
  }

  fileprivate func updateViewState(newState: KNKYCStepViewState) {
    let width = self.view.frame.width
    let height = self.view.frame.height - self.scrollView.frame.minY

    self.viewModel.updateStepState(newState)
    self.stepView.updateView(with: self.viewModel.stepState)

    let rect = CGRect(
      x: CGFloat(self.viewModel.stepState.rawValue) * width,
      y: 0,
      width: width,
      height: height
    )
    self.scrollView.scrollRectToVisible(rect, animated: true)
  }
}

extension KYCFlowViewController: KYCPersonalInfoViewControllerDelegate {
  func kycPersonalInfoViewController(_ controller: KYCPersonalInfoViewController, run event: KYCPersonalInfoViewEvent) {
    switch event {
    case .next:
      self.updateViewState(newState: .id)
    }
  }
}

extension KYCFlowViewController: KYCIdentityInfoViewControllerDelegate {
  func identityInfoViewController(_ controller: KYCIdentityInfoViewController, run event: KYCIdentityInfoViewEvent) {
    switch event {
    case .next:
      self.updateViewState(newState: .submit)
    }
  }
}
