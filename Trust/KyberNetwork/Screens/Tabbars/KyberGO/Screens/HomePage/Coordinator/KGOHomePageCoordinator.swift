// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import BigInt
import TrustKeystore
import Result
import SafariServices

class KGOHomePageCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession

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

  fileprivate var buyTokenVC: IEOBuyTokenViewController?
  fileprivate var setGasPriceVC: KNSetGasPriceViewController?

  deinit {
    self.ieoListTimer?.invalidate()
    self.ieoListTimer = nil
    self.nodeDataTimer?.invalidate()
    self.nodeDataTimer = nil
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(kIEODidReceiveCallbackNotificationKey),
      object: nil
    )
  }

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
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
    let callbackName = Notification.Name(kIEODidReceiveCallbackNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.appCoordinatorDidReceiveCallback(_:)),
      name: callbackName,
      object: nil
    )
  }

  func stop() {
    self.ieoListTimer?.invalidate()
    self.nodeDataTimer?.invalidate()
  }

  func updateSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.buyTokenVC?.coordinatorDidUpdateWalletObjects()
  }

  fileprivate func initialLoadListKGO() {
    var isLoadingShown: Bool = false
    if IEOObjectStorage.shared.objects.isEmpty {
      self.navigationController.displayLoading()
      isLoadingShown = true
    }
    self.reloadListKGO { [weak self] result in
      guard let `self` = self else { return }
      if isLoadingShown { self.navigationController.hideLoading() }
      if case .failure(let error) = result {
        self.navigationController.displayError(error: error)
      }
    }
  }

  fileprivate func reloadListKGO(completion: ((Result<Bool, AnyError>) -> Void)? = nil) {
    DispatchQueue.global().async {
      let provider = MoyaProvider<KyberGOService>()
      provider.request(.listIEOs, completion: { [weak self] result in
        DispatchQueue.main.async(execute: {
          switch result {
          case .success(let resp):
            do {
              guard let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary else { return }
              if let dataArr = json["data"] as? [JSONDictionary] {
                let objects = dataArr.map({ json -> IEOObject in
                  var object = IEOObject(dict: json)
                  if let objc = IEOObjectStorage.shared.getObject(primaryKey: object.id) {
                    object = IEOObjectStorage.shared.update(object: object, from: objc)
                  }
                  return object
                })
                IEOObjectStorage.shared.update(objects: objects)
                self?.rootViewController.coordinatorDidUpdateListKGO(IEOObjectStorage.shared.objects)
              }
              completion?(.success(true))
            } catch {
              completion?(.success(false))
              print("Error to map result")
            }
          case .failure(let error):
            completion?(.failure(AnyError(error)))
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
      // not update upcoming token sales
      return obj.startDate.timeIntervalSince(Date()) < 0
    }
    for object in objects {
      if object.needsUpdateRate {
        // get rate if it is not ended
        IEOProvider.shared.getRate(for: object.contract, completion: { result in
          switch result {
          case .success(let data):
            if !data.1.isZero {
              let rate = (data.0 * BigInt(10).power(object.tokenDecimals) / data.1)
              let rateString = rate.string(decimals: object.tokenDecimals, minFractionDigits: 6, maxFractionDigits: 6)
              IEOObjectStorage.shared.update(rate: rateString, object: object)
              self.ieoListViewController?.coordinatorDidUpdateRate(rate, object: object)
              self.buyTokenVC?.coordinatorDidUpdateEstRate(for: object, rate: rate)
            }
          case .failure(let error):
            print("Error: \(error.prettyError)")
          }
        })
      }

      if object.needsUpdateRaised {
        // get raised data if it is not ended
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
}

extension KGOHomePageCoordinator: KGOHomePageViewControllerDelegate {

  func kyberGOHomePageViewController(_ controller: KGOHomePageViewController, run event: KGOHomePageViewEvent) {
    switch event {
    case .select(let object, let listObjects):
      self.openListIEOView(selectedObject: object, listObjects: listObjects)
    case .selectAccount:
      self.userSelectedAccount()
    case .selectBuy(let object):
      self.openBuy(object: object)
    }
  }

  fileprivate func userSelectedAccount() {
    guard let user = IEOUserStorage.shared.user else {
      self.openSignInView()
      return
    }
    let alertController = UIAlertController(title: "", message: "You are signed in as \(user.name). Do you want to sign out?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Keep Sign In", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { _ in
      IEOUserStorage.shared.deleteAll()
      self.rootViewController.coordinatorDidSignOut()
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func openListIEOView(selectedObject: IEOObject, listObjects: [IEOObject]) {
    self.ieoListViewController = {
      let viewModel: IEOListViewModel = {
        let title: String = {
          switch selectedObject.type {
          case .past: return "Past Token Sales"
          case .active: return "Active Token Sales"
          case .upcoming: return "Upcoming Token Sales"
          }
        }()
        return IEOListViewModel(
          objects: listObjects,
          curObject: selectedObject,
          title: title
        )
      }()
      let controller = IEOListViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      controller.modalTransitionStyle = .crossDissolve
      return controller
    }()
    self.navigationController.pushViewController(self.ieoListViewController!, animated: true)
  }

  fileprivate func openSignInView() {
    if let user = IEOUserStorage.shared.objects.first {
      // User already signed in
      self.navigationController.showSuccessTopBannerMessage(with: "Hi \(user.name)", message: "You have signed in successfully! You could buy tokens now")
      return
    }
    if let url = URL(string: "https://kyber.mangcut.vn/oauth/authorize?client_id=\(KNSecret.appID)&redirect_uri=\(KNSecret.redirectURL)&response_type=code&state=\(KNSecret.state)") {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  @objc func appCoordinatorDidReceiveCallback(_ sender: Notification) {
    if IEOUserStorage.shared.objects.first != nil { return } // return if user exists
    guard let params = sender.object as? JSONDictionary else { return }
    guard let code = params["code"] as? String, let state = params["state"] as? String, state == KNSecret.state else { return }
    // got authentication code from KyberGO
    // use the code to get access token for user
    let provider = MoyaProvider<KyberGOService>()
    let accessToken = KyberGOService.getAccessToken(code: code)
    provider.request(accessToken, completion: { [weak self] result in
      guard let _ = `self` else { return }
      switch result {
      case .success(let data):
        if let dataJSON = try? data.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let json = dataJSON {
          guard let accessToken = json["access_token"] as? String else { return }
          // got access token, user access token to retrieve user information
          let userInfoRequest = KyberGOService.getUserInfo(accessToken: accessToken)
          provider.request(userInfoRequest, completion: { [weak self] userInfoResult in
            guard let _ = `self` else { return }
            switch userInfoResult {
            case .success(let userInfo):
              guard let userDataJSON = try? userInfo.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let userJSON = userDataJSON else { return }
              let user = IEOUser(dict: userJSON)
              IEOUserStorage.shared.update(objects: [user])
              IEOUserStorage.shared.updateToken(object: user, dict: json)
              self?.navigationController.showSuccessTopBannerMessage(with: "Hi \(user.name)", message: "You have signed in successfully! You could buy tokens now")
              self?.rootViewController.coordinatorUserDidSignInSuccessfully()
              // Already have user
            case .failure(let error):
              self?.navigationController.displayError(error: error)
            }
          })
        }
      case .failure(let error):
        self?.navigationController.displayError(error: error)
      }
    })
  }

  fileprivate func openBuy(object: IEOObject) {
    guard IEOUserStorage.shared.user != nil else {
      self.openSignInView()
      return
    }
    guard let wallet = KNWalletStorage.shared.wallets.first(where: {
      $0.address.lowercased() == self.session.wallet.address.description.lowercased()
    }) else { return }
    let viewModel = IEOBuyTokenViewModel(to: object, walletObject: wallet)
    self.buyTokenVC = IEOBuyTokenViewController(viewModel: viewModel)
    self.buyTokenVC?.loadViewIfNeeded()
    self.buyTokenVC?.delegate = self
    self.navigationController.pushViewController(self.buyTokenVC!, animated: true)
  }

  fileprivate func getContributorRemainingCap(userID: Int, contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    IEOProvider.shared.getContributorRemainingCap(
      contractAddress: contract,
      userID: userID,
      completion: completion
    )
  }

  fileprivate func getSignData(userID: Int, address: String, ieoID: Int, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let provider = MoyaProvider<KyberGOService>()
    let service = KyberGOService.getSignedTx(
      userID: userID,
      ieoID: ieoID,
      address: address,
      time: UInt(floor(Date().timeIntervalSince1970)) * 1000
    )
    provider.request(service) { result in
      switch result {
      case .success(let resp):
        if let data = try? resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let json = data {
          completion(.success(json))
        } else {
          completion(.success(["reason": "Can not parse response data"]))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

extension KGOHomePageCoordinator: IEOListViewControllerDelegate {
  func ieoListViewController(_ controller: IEOListViewController, run event: IEOListViewEvent) {
    switch event {
    case .dismiss:
      self.navigationController.popViewController(animated: true)
    case .buy(let object):
      self.openBuy(object: object)
    }
  }
}

extension KGOHomePageCoordinator: IEOBuyTokenViewControllerDelegate {
  func ieoBuyTokenViewController(_ controller: IEOBuyTokenViewController, run event: IEOBuyTokenViewEvent) {
    switch event {
    case .close:
      self.navigationController.popViewController(animated: true)
    case .selectSetGasPrice(let gasPrice, let gasLimit):
      let setGasPriceVC: KNSetGasPriceViewController = {
        let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: gasLimit)
        let controller = KNSetGasPriceViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        return controller
      }()
      self.setGasPriceVC = setGasPriceVC
      self.navigationController.pushViewController(setGasPriceVC, animated: true)
    case .selectBuyToken, .selectIEO: break
    case .buy(let transaction):
      guard let userID = IEOUserStorage.shared.user?.userID else {
        self.showAlertUserNotSignIn()
        return
      }
      self.getSignData(
        userID: userID,
        address: transaction.wallet.address,
        ieoID: transaction.ieo.id,
        completion: { [weak self] result in
        guard let `self` = self else { return }
          switch result {
          case .success(let data):
            guard let v = data["v"] as? String, let r = data["r"] as? String, let s = data["s"] as? String else {
              let reason = data["reason"] as? String ?? "Something went wrong"
              self.navigationController.showWarningTopBannerMessage(with: "Error", message: reason)
              return
            }
            transaction.update(userID: userID)
            transaction.update(v: v, r: r, s: s)
            self.sendBuyTransaction(transaction)
          case .failure(let error):
            self.navigationController.displayError(error: error)
          }
      })
    }
  }

  fileprivate func sendBuyTransaction(_ transaction: IEODraftTransaction) {
    guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == transaction.wallet.address.lowercased() }) else { return }
    if case .real(let account) = wal.type {
      self.navigationController.displayLoading()
      IEOProvider.shared.buy(
        transaction: transaction,
        account: account,
        keystore: self.session.keystore,
        completion: { [weak self] result in
          self?.navigationController.hideLoading()
          switch result {
          case .success(let resp):
            self?.showBroadcastSuccessfully(resp)
          case .failure(let error):
            self?.navigationController.displayError(error: error)
          }
      })
    }
  }

  fileprivate func showBroadcastSuccessfully(_ hash: String) {
    let alertController = UIAlertController(title: "Successfully", message: "Your transaction is being mined", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Open Details", style: .default, handler: { _ in
      if let url = URL(string: "\(KNEnvironment.default.etherScanIOURLString)tx/\(hash)") {
        let safariVC = SFSafariViewController(url: url)
        self.navigationController.present(safariVC, animated: true, completion: nil)
      }
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func showAlertUserNotSignIn() {
    let alertController = UIAlertController(
      title: "Sign In Required",
      message: "You are not signed in with KyberGO. Please sign in to continue.",
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { _ in
      if let url = URL(string: "https://kyber.mangcut.vn/oauth/authorize?client_id=\(KNSecret.appID)&redirect_uri=\(KNSecret.redirectURL)&response_type=code&state=\(KNSecret.state)") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

extension KGOHomePageCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      self.buyTokenVC?.coordinatorBuyTokenDidUpdateGasPrice(gasPrice)
      self.setGasPriceVC = nil
    }
  }
}
