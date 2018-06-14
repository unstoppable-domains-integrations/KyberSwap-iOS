// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import BigInt

class KGOHomePageCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []

  lazy var rootViewController: KGOHomePageViewController = {
    let viewModel = KGOHomePageViewModel(objects: IEOObjectStorage.shared.objects)
    let controller = KGOHomePageViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var ieoListViewController: IEOListViewController?
  fileprivate var ieoListTimer: Timer?
  fileprivate var nodeDataTimer: Timer?

  deinit {
    self.ieoListTimer?.invalidate()
    self.ieoListTimer = nil
    self.nodeDataTimer?.invalidate()
    self.nodeDataTimer = nil
  }

  init(
    navigationController: UINavigationController = UINavigationController()
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.ieoListTimer?.invalidate()
    self.initialLoadListKGO()
    self.ieoListTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.loadingListIEOInterval,
      repeats: true,
      block: { [weak self] _ in
      self?.reloadListKGO()
    })
    self.nodeDataTimer?.invalidate()
    self.reloadIEODataFromNode()
    self.nodeDataTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadIEODataFromNode()
    })
  }

  func stop() {
    self.ieoListTimer?.invalidate()
    self.nodeDataTimer?.invalidate()
  }

  fileprivate func initialLoadListKGO() {
    var isLoadingShown: Bool = false
    if IEOObjectStorage.shared.objects.isEmpty {
      self.navigationController.displayLoading()
      isLoadingShown = true
    }
    self.reloadListKGO {
      if isLoadingShown {
        self.navigationController.hideLoading()
      }
    }
  }

  fileprivate func reloadListKGO(completion: (() -> Void)? = nil) {
    DispatchQueue.global().async {
      let provider = MoyaProvider<KyberGOService>()
      provider.request(.listIEOs, completion: { [weak self] result in
        DispatchQueue.main.async(execute: {
          switch result {
          case .success(let resp):
            do {
              guard let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary else { return }
              if let data = json["data"] as? [JSONDictionary] {
                let objects = data.map({ return IEOObject(dict: $0) })
                IEOObjectStorage.shared.update(objects: objects)
                self?.rootViewController.coordinatorDidUpdateListKGO(IEOObjectStorage.shared.objects)
              }
            } catch {
              print("Error to map result")
            }
            completion?()
          case .failure:
            print("Failed to load list IEOs")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +  5.0, execute: {
              self?.reloadListKGO()
            })
          }
        })
      })
    }
  }

  fileprivate func reloadIEODataFromNode() {
    let objects = IEOObjectStorage.shared.objects.filter { obj -> Bool in
      return Date().timeIntervalSince(obj.endDate) <= 60.0 && obj.startDate.timeIntervalSince(Date()) < 0
    }
    for object in objects {
      // get rate
      IEOProvider.shared.getRate(for: object.contract, completion: { result in
        switch result {
        case .success(let data):
          if !data.1.isZero {
            let rate = (data.0 * BigInt(10).power(object.tokenDecimals) / data.1)
            let rateString = rate.string(decimals: object.tokenDecimals, minFractionDigits: 6, maxFractionDigits: 6)
            IEOObjectStorage.shared.update(rate: rateString, object: object)
            self.ieoListViewController?.coordinatorDidUpdateRate(rate, object: object)
          }
        case .failure(let error):
          print("Error: \(error.prettyError)")
        }
      })

      // get raised data
      IEOProvider.shared.getDistributedTokensWei(for: object.contract) { [weak self] result in
        switch result {
        case .success(let value):
          let raised = Double(value / BigInt(10).power(object.tokenDecimals))
            IEOObjectStorage.shared.update(raised: raised, object: object)
          self?.rootViewController.coordinatorDidUpdateListKGO(IEOObjectStorage.shared.objects)
          self?.ieoListViewController?.coordinatorDidUpdateProgress()
        case .failure(let error):
          print("Error: \(error.prettyError)")
        }
      }
    }
  }
}

extension KGOHomePageCoordinator: KGOHomePageViewControllerDelegate {
  func kyberGOHomePageViewController(_ controller: KGOHomePageViewController, didSelect object: IEOObject) {
    self.ieoListViewController = {
      let viewModel: IEOListViewModel = {
        let listObjects = IEOObjectStorage.shared.objects.filter { return $0.type == object.type }
        let title: String = {
          switch object.type {
          case .past: return "Past KGO"
          case .active: return "Active KGO"
          case .upcoming: return "Upcoming KGO"
          }
        }()
        return IEOListViewModel(
          objects: listObjects,
          curObject: object,
          title: title
        )
      }()
      let controller = IEOListViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      controller.modalTransitionStyle = .crossDissolve
      return controller
    }()
    self.navigationController.present(self.ieoListViewController!, animated: true, completion: nil)
  }
}

extension KGOHomePageCoordinator: IEOListViewControllerDelegate {
  func ieoListViewControllerDidDismiss() {
    self.ieoListViewController = nil
  }
}
