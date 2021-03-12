//
//  InvestCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/12/21.
//

import Foundation

class InvestCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  
  lazy var rootViewController: InvestViewController = {
    let controller = InvestViewController()
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
  }
  
  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func stop() {
    
  }
}
