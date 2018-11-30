// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KYCCoordinatorDelegate: class {
  func kycCoordinatorDidSubmitData()
  func kycCoordinatorDidBack()
}

class KYCCoordinator: Coordinator {

  weak var delegate: KYCCoordinatorDelegate?
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  let user: IEOUser

  lazy var kycFlowVC: KYCFlowViewController = {
    let viewModel = KYCFlowViewModel(user: self.user)
    let controller = KYCFlowViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(
    navigationController: UINavigationController,
    user: IEOUser
    ) {
    self.user = user
    self.navigationController = navigationController
  }

  func start() {
    self.navigationController.pushViewController(self.kycFlowVC, animated: true)
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: true)
  }
}

extension KYCCoordinator: KYCFlowViewControllerDelegate {
  func kycFlowViewController(_ controller: KYCFlowViewController, run event: KYCFlowViewEvent) {
    self.stop()
    if case .submitted = event {
      self.delegate?.kycCoordinatorDidSubmitData()
    } else {
      self.delegate?.kycCoordinatorDidBack()
    }
  }
}
