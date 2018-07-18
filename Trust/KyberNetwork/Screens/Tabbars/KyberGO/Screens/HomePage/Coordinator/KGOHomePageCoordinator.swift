// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import BigInt
import TrustKeystore
import TrustCore
import Result
import SafariServices

//swiftlint:disable file_length
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
  fileprivate var kyberGOTxListTimer: Timer?
  fileprivate var accessTokenExpireTimer: Timer?

  fileprivate var buyTokenVC: IEOBuyTokenViewController?
  fileprivate var setGasPriceVC: KNSetGasPriceViewController?
  fileprivate var profileVC: IEOProfileViewController?

  deinit { self.stop() }

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
    self.timerLoadIEOList()
    self.timerLoadDataFromNode()
    self.timerLoadKyberGOTxList()
    self.timerAccessTokenExpired()

    // Add notification observer
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
    self.ieoListTimer = nil
    self.nodeDataTimer?.invalidate()
    self.nodeDataTimer = nil
    self.kyberGOTxListTimer?.invalidate()
    self.kyberGOTxListTimer = nil
    self.accessTokenExpireTimer?.invalidate()
    self.accessTokenExpireTimer = nil

    // Remove notification observer
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(kIEODidReceiveCallbackNotificationKey),
      object: nil
    )
  }

  fileprivate func timerAccessTokenExpired() {
    if let user = IEOUserStorage.shared.user {
      let time = Date(timeIntervalSince1970: user.expireTime).timeIntervalSinceNow
      guard time > 0 else {
        self.handleUserAccessTokenExpired()
        return
      }
      self.accessTokenExpireTimer?.invalidate()
      self.accessTokenExpireTimer = Timer.scheduledTimer(
        withTimeInterval: time,
        repeats: false,
        block: { [weak self] _ in
          self?.handleUserAccessTokenExpired()
      })
    }
  }

  fileprivate func timerLoadIEOList() {
    self.ieoListTimer?.invalidate()
    self.initialLoadListKGO()
    self.ieoListTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.loadingListIEOInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadListKGO()
    })
  }

  fileprivate func timerLoadDataFromNode() {
    self.nodeDataTimer?.invalidate()
    self.reloadIEODataFromNode()
    self.nodeDataTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadIEODataFromNode()
    })
  }

  fileprivate func timerLoadKyberGOTxList() {
    self.kyberGOTxListTimer?.invalidate()
    self.reloadKyberGOTransactionList()
    self.kyberGOTxListTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadKyberGOTransactionList()
    })
  }

  fileprivate func handleUserAccessTokenExpired() {
    guard let user = IEOUserStorage.shared.user else { return }
    let refreshToken = user.refreshToken
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      let request = KyberGOService.getAccessToken(code: refreshToken, isRefresh: true)
      provider.request(request) { [weak self] result in
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              _ = try data.filterSuccessfulStatusCodes()
              if let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary,
                let accessToken = json["access_token"] as? String,
                let tokenType = json["token_type"] as? String,
                let refreshToken = json["refresh_token"] as? String,
                let expireTime = json["expires_in"] as? Double {
                IEOUserStorage.shared.updateToken(
                  object: user,
                  type: tokenType,
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                  expireTime: expireTime
                )
                self?.timerAccessTokenExpired()
                return
              }
            } catch {}
          case .failure:
            break
          }
          // Error for some reason
          KNNotificationUtil.localPushNotification(
            title: "Session expired",
            body: "Your session has expired, please sign in again to continue"
          )
          IEOUserStorage.shared.signedOut()
          self?.navigationController.popToRootViewController(animated: true)
          self?.rootViewController.coordinatorDidSignOut()
        }
      }
    }
  }

  // MARK: Update from app coordinator
  func updateSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.buyTokenVC?.coordinatorDidUpdateWalletObjects()
  }

  // MARK: Initial load list KyberGO, show error if needed
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

  fileprivate func openConfirmView(for transaction: IEODraftTransaction) {
    let viewModel: KNConfirmTransactionViewModel = {
      let type = KNTransactionType.buyTokenSale(transaction)
      return KNConfirmTransactionViewModel(type: type)
    }()
    let confirmVC = KNConfirmTransactionViewController(viewModel: viewModel)
    confirmVC.delegate = self
    confirmVC.modalPresentationStyle = .overFullScreen
    confirmVC.modalTransitionStyle = .crossDissolve
    self.navigationController.present(confirmVC, animated: true, completion: nil)
  }

  fileprivate func sendLocalPushNotification(transaction: IEOTransaction, ieo: IEOObject) {
    let details: String = {
      switch transaction.txStatus {
      case .success:
        let distributedAmount = BigInt(transaction.distributedTokensWei).string(
          decimals: ieo.tokenDecimals,
          minFractionDigits: 0,
          maxFractionDigits: 4
        )
        return "Successfully bought \(distributedAmount) \(ieo.tokenSymbol) from token sale \(ieo.name)"
      case .lost:
        return "Your transaction of buying token sale \(ieo.name) has been lost"
      case .fail:
        return "Failed to buy token sale \(ieo.name)"
      default: return ""
      }
    }()
    KNNotificationUtil.localPushNotification(
      title: transaction.status,
      body: details
    )
  }
}

// MARK: KGO Home Page VC Delegation
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
    guard let _ = IEOUserStorage.shared.user else {
      self.openSignInView()
      return
    }
    self.profileVC = IEOProfileViewController(viewModel: IEOProfileViewModel())
    self.profileVC?.delegate = self
    self.navigationController.pushViewController(self.profileVC!, animated: true)
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

  fileprivate func openBuy(object: IEOObject) {
    guard IEOUserStorage.shared.user != nil else {
      self.showAlertUserNotSignIn()
      return
    }
    self.navigationController.displayLoading(text: "Checking...", animated: true)
    self.checkIEOWhitelisted(ieo: object) { [weak self] result in
      self?.navigationController.hideLoading()
      guard let `self` = self else { return }
      switch result {
      case .success(let canBuy):
        guard canBuy else {
          self.navigationController.showWarningTopBannerMessage(
            with: "Error",
            message: "You are not whitelisted for this token sale.".toBeLocalised()
          )
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
        return
      case .failure(let error):
        self.navigationController.showWarningTopBannerMessage(
          with: "Error",
          message: error.prettyError
        )
      }
    }
  }
}

// MARK: KyberGO OAuth
extension KGOHomePageCoordinator {
  fileprivate func openSignInView() {
    if let user = IEOUserStorage.shared.user {
      // User already signed in
      self.navigationController.showSuccessTopBannerMessage(with: "Hi \(user.name)", message: "You have signed in successfully! You could buy tokens now")
      return
    }
    if let user = IEOUserStorage.shared.objects.first, Date(timeIntervalSince1970: user.expireTime).timeIntervalSinceNow > 0 {
      IEOUserStorage.shared.signedIn()
      self.getUserInfo(
        type: user.tokenType,
        accessToken: user.accessToken,
        refreshToken: user.refreshToken,
        expireTime: user.expireTime
      )
      return
    }
    //TODO: Change to prod app id
    if let url = URL(string: KNAppTracker.getKyberGOBaseString() + "/oauth/authorize?client_id=\(KNSecret.debugAppID)&redirect_uri=\(KNSecret.redirectURL)&response_type=code&state=\(KNSecret.state)") {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  @objc func appCoordinatorDidReceiveCallback(_ sender: Notification) {
    if IEOUserStorage.shared.user != nil { return } // return if user exists
    guard let params = sender.object as? JSONDictionary else { return }
    guard let code = params["code"] as? String, let state = params["state"] as? String, state.contains(KNSecret.state) else { return }
    // got authentication code from KyberGO
    // use the code to get access token for user
    self.navigationController.displayLoading(text: "Initial Session...", animated: true)
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      let accessToken = KyberGOService.getAccessToken(code: code, isRefresh: false)
      provider.request(accessToken, completion: { [weak self] result in
        DispatchQueue.main.async {
          guard let _ = `self` else { return }
          switch result {
          case .success(let data):
            do {
              _ = try data.filterSuccessfulStatusCodes()
              let dataJSON: JSONDictionary = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              guard let accessToken = dataJSON["access_token"] as? String,
                let tokenType = dataJSON["token_type"] as? String,
                let refreshToken = dataJSON["refresh_token"] as? String,
                let expireTime = dataJSON["expires_in"] as? Double
                else {
                  self?.navigationController.hideLoading()
                  self?.navigationController.showWarningTopBannerMessage(
                    with: "Error",
                    message: "Can not get access token".toBeLocalised()
                  )
                  return
              }
              self?.getUserInfo(
                type: tokenType,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expireTime: Date().addingTimeInterval(expireTime).timeIntervalSince1970
              )
            } catch {
              self?.navigationController.hideLoading()
              self?.navigationController.showWarningTopBannerMessage(
                with: "Error",
                message: "Can not get access token".toBeLocalised()
              )
            }
          case .failure(let error):
            self?.navigationController.hideLoading()
            self?.navigationController.displayError(error: error)
          }
        }
      })
    }
  }

  fileprivate func getUserInfo(type: String, accessToken: String, refreshToken: String, expireTime: Double) {
    // got access token, user access token to retrieve user information
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      let userInfoRequest = KyberGOService.getUserInfo(accessToken: accessToken)
      provider.request(userInfoRequest, completion: { [weak self] userInfoResult in
        DispatchQueue.main.async {
          guard let _ = `self` else { return }
          self?.navigationController.hideLoading()
          switch userInfoResult {
          case .success(let userInfo):
            guard let userDataJSON = try? userInfo.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let userJSON = userDataJSON else {
              self?.navigationController.showWarningTopBannerMessage(
                with: "Error",
                message: "Can not get user info"
              )
              return
            }
            let user = IEOUser(dict: userJSON)
            IEOUserStorage.shared.update(objects: [user])
            IEOUserStorage.shared.updateToken(
              object: user,
              type: type,
              accessToken: accessToken,
              refreshToken: refreshToken,
              expireTime: expireTime
            )
            self?.timerAccessTokenExpired()
            IEOTransactionStorage.shared.userLoggedIn()
            self?.navigationController.showSuccessTopBannerMessage(
              with: "Hi \(user.name)",
              message: "You have signed in successfully! You could buy token sales now".toBeLocalised()
            )
            self?.rootViewController.coordinatorUserDidSignInSuccessfully()
          // Already have user
          case .failure(let error):
            self?.navigationController.displayError(error: error)
          }
        }
      })
    }
  }
}

// MARK: KyberGO Provider (Networking)
extension KGOHomePageCoordinator {
  fileprivate func reloadListKGO(completion: ((Result<Bool, AnyError>) -> Void)? = nil) {
    NSLog("----KyberGO: reload list KGO----")
    DispatchQueue.global().async {
      let provider = MoyaProvider<KyberGOService>()
      provider.request(.listIEOs, completion: { [weak self] result in
        DispatchQueue.main.async(execute: {
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
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
              NSLog("----KyberGO: reload list KGO successfully----")
              completion?(.success(true))
            } catch {
              NSLog("----KyberGO: reload list KGO parse error----")
              completion?(.success(false))
            }
          case .failure(let error):
            completion?(.failure(AnyError(error)))
            NSLog("----KyberGO: reload list KGO failed with error: \(error.prettyError)----")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +  5.0, execute: {
              self?.reloadListKGO()
            })
          }
        })
      })
    }
  }

  fileprivate func checkIEOWhitelisted(ieo: IEOObject, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let user = IEOUserStorage.shared.user else {
      completion(.success(false))
      return
    }
    NSLog("----KyberGO: Check can participate----")
    let accessToken: String = user.accessToken
    let ieoID: Int = ieo.id
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      provider.request(.checkParticipate(accessToken: accessToken, ieoID: ieoID)) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              guard let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary else {
                NSLog("----KyberGO: Check can participate parse error----")
                completion(.success(false))
                return
              }
              NSLog("----KyberGO: Check can participate successfully data: \(json)----")
              let canParticipate: Bool = {
                guard let data = json["data"] as? JSONDictionary else { return false }
                return data["can_participate"] as? Bool ?? false
              }()
              completion(.success(canParticipate))
            } catch let error {
              NSLog("----KyberGO: Check can participate parse error: \(error.prettyError)----")
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            NSLog("----KyberGO: Check can participate failed error: \(error.prettyError)----")
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  fileprivate func getSignData(userID: Int, address: String, ieoID: Int, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    NSLog("----KyberGO: Get Sign Data----")
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      let service = KyberGOService.getSignedTx(
        userID: userID,
        ieoID: ieoID,
        address: address,
        time: UInt(floor(Date().timeIntervalSince1970)) * 1000
      )
      provider.request(service) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let resp):
            if let data = try? resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let json = data {
              NSLog("----KyberGO: Get Sign Data Successfully: \(json)----")
              completion(.success(json))
            } else {
              NSLog("----KyberGO: Get Sign Data Parse Error")
              completion(.success(["reason": "Can not parse response data"]))
            }
          case .failure(let error):
            NSLog("----KyberGO: Get Sign Data Error \(error.prettyError)----")
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  fileprivate func reloadKyberGOTransactionList(completion: ((Result<[IEOTransaction], AnyError>) -> Void)? = nil) {
    self.fetchKyberGOTxList { [weak self] result in
      if case .success(let transactions) = result {
        var txMap: [String: IEOTransaction] = [:]
        transactions.forEach({ txMap[$0.txHash] = $0 })
        var ieoMap: [Int: IEOObject] = [:]
        IEOObjectStorage.shared.objects.forEach({ ieoMap[$0.id] = $0 })
        IEOTransactionStorage.shared.objects.forEach({ tran in
          //TODO: Show local push notification
          if tran.txStatus == .pending, let tx = txMap[tran.txHash], tx.txStatus != .pending, let ieo = ieoMap[tx.ieoID] {
            self?.sendLocalPushNotification(transaction: tx, ieo: ieo)
          }
        })
        IEOTransactionStorage.shared.update(objects: transactions)
        let trans = IEOTransactionStorage.shared.objects

        // Update badge for kybergo tab
        if let tabItems = self?.navigationController.tabBarController?.tabBar.items {
          let values = trans.filter({ !$0.viewed }).count
          tabItems[2].badgeValue = values > 0 ? "\(values)" : nil
        }
        self?.profileVC?.coordinatorUpdateTransactionList(trans)
        self?.rootViewController.coordinatorUpdateListKyberGOTx(
          transactions: trans
        )
      }
      completion?(result)
    }
  }

  fileprivate func fetchKyberGOTxList(completion: ((Result<[IEOTransaction], AnyError>) -> Void)?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken, !accessToken.isEmpty else {
      // no user
      completion?(.success([]))
      return
    }
    NSLog("----KyberGO: reload KyberGO Tx list----")
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      provider.request(.getTxList(accessToken: accessToken)) { [weak self] result in
        DispatchQueue.main.async {
          guard let _ = self else { return }
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              let jsonData: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let jsonArr = jsonData["data"] as? [JSONDictionary] ?? []
              let transactions = jsonArr.map({ return IEOTransaction(dict: $0) })
              NSLog("----KyberGO: reload KyberGO Tx list successully \(transactions.count) transactions----")
              completion?(.success(transactions))
            } catch let error {
              NSLog("----KyberGO: reload KyberGO Tx list error: \(error.prettyError)----")
              completion?(.failure(AnyError(error)))
            }
          case .failure(let error):
            NSLog("----KyberGO: reload KyberGO Tx list error: \(error.prettyError)----")
            completion?(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}

// MARK: KyberGO SmartContract
extension KGOHomePageCoordinator {
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

  fileprivate func getContributorRemainingCap(userID: Int, contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    IEOProvider.shared.getContributorRemainingCap(
      contractAddress: contract,
      userID: userID,
      completion: completion
    )
  }

  fileprivate func sendBuyTransaction(_ transaction: IEODraftTransaction) {
    self.waitingForGettingSignData(transaction: transaction) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let trans) = result, let newTransaction = trans {
        guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == transaction.wallet.address.lowercased() }) else { return }
        if case .real(let account) = wal.type {
          self.navigationController.displayLoading(text: "Broadcasting...", animated: true)
          IEOProvider.shared.buy(
            transaction: newTransaction,
            account: account,
            keystore: self.session.keystore,
            completion: { [weak self] result in
              self?.navigationController.hideLoading()
              switch result {
              case .success(let resp):
                self?.didFinishBuyTokenWithHash(resp, draftTx: newTransaction)
              case .failure(let error):
                self?.navigationController.displayError(error: error)
              }
          })
        }
      }
    }
  }

  fileprivate func waitingForGettingSignData(transaction: IEODraftTransaction, completion: @escaping (Result<IEODraftTransaction?, AnyError>) -> Void) {
    guard let userID = IEOUserStorage.shared.user?.userID else { return }
    self.navigationController.displayLoading(text: "Getting sign data...", animated: true)
    self.getSignData(
      userID: userID,
      address: transaction.wallet.address,
      ieoID: transaction.ieo.id,
      completion: { [weak self] result in
        guard let `self` = self else { return }
        self.navigationController.hideLoading()
        switch result {
        case .success(let data):
          guard let v = data["v"] as? String, let r = data["r"] as? String, let s = data["s"] as? String else {
            let reason = data["reason"] as? String ?? "Something went wrong".toBeLocalised()
            self.navigationController.showWarningTopBannerMessage(with: "Error", message: reason)
            completion(.success(nil))
            return
          }
          transaction.update(v: v, r: r, s: s)
          completion(.success(transaction))
        case .failure(let error):
          self.navigationController.displayError(error: error)
          completion(.failure(error))
        }
    })
  }
}

// MARK: KGO IEO List View Delegation
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

// MARK: KGO IEO Buy View Delegation
extension KGOHomePageCoordinator: IEOBuyTokenViewControllerDelegate {
  func ieoBuyTokenViewController(_ controller: IEOBuyTokenViewController, run event: IEOBuyTokenViewEvent) {
    switch event {
    case .close:
      self.navigationController.popViewController(animated: true) {
        self.buyTokenVC = nil
      }
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
      transaction.update(userID: userID)
      self.openConfirmView(for: transaction)
    }
  }

  fileprivate func didFinishBuyTokenWithHash(_ hash: String, draftTx: IEODraftTransaction) {
    self.navigationController.showSuccessTopBannerMessage(
      with: "Broadcasted".toBeLocalised(),
      message: "Transaction has been successfully broadcasted".toBeLocalised()
    )
    self.addTransactionRequest(draftTx: draftTx, hash: hash)
  }

  // Add transaction until it is success
  fileprivate func addTransactionRequest(draftTx: IEODraftTransaction, hash: String) {
    let provider = MoyaProvider<KyberGOService>()
    let request = KyberGOService.createTx(
      ieoID: draftTx.ieo.id,
      srcAddress: draftTx.wallet.address,
      hash: hash,
      accessToken: IEOUserStorage.shared.user?.accessToken ?? "")
    NSLog("----KyberGO: Add transaction----")
    DispatchQueue.global(qos: .background).async {
      provider.request(request) { [weak self] result in
        DispatchQueue.main.async {
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              self?.reloadKyberGOTransactionList()
              return
            } catch let error {
              NSLog("----KyberGO: Add transaction failed with error: \(error.prettyError)----")
            }
          case .failure(let error):
            NSLog("----KyberGO: Add transaction failed with error: \(error.prettyError)----")
          }
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
            self?.addTransactionRequest(draftTx: draftTx, hash: hash)
          })
        }
      }
    }
  }

  fileprivate func showAlertUserNotSignIn() {
    let alertController = UIAlertController(
      title: "Sign In Required".toBeLocalised(),
      message: "You are not signed in with KyberGO. Please sign in to continue.".toBeLocalised(),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Cancel".toBeLocalised(), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Sign In".toBeLocalised(), style: .default, handler: { _ in
      self.openSignInView()
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Set Gas View Delegation
extension KGOHomePageCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      self.buyTokenVC?.coordinatorBuyTokenDidUpdateGasPrice(gasPrice)
      self.setGasPriceVC = nil
    }
  }
}

// MARK: IEO Profile Delegation
extension KGOHomePageCoordinator: IEOProfileViewControllerDelegate {
  func ieoProfileViewController(_ controller: IEOProfileViewController, run event: IEOProfileViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true) {
        self.profileVC = nil
      }
    case .select(let transaction): self.openEtherScan(for: transaction)
    case .signedOut:
      self.userSelectSignOut()
    case .viewDidAppear:
      self.reloadKGOTransactionListViewDidAppear()
    }
  }

  private func openEtherScan(for transaction: IEOTransaction) {
    let urlString = KNEnvironment.default.etherScanIOURLString + "tx/\(transaction.txHash)"
    self.profileVC?.openSafari(with: urlString)
  }

  private func userSelectSignOut() {
    self.navigationController.popViewController(animated: true) {
      IEOUserStorage.shared.signedOut()
      self.navigationController.popToRootViewController(animated: true)
      self.profileVC = nil
      self.buyTokenVC = nil
      self.setGasPriceVC = nil
      self.rootViewController.coordinatorDidSignOut()
    }
  }

  private func reloadKGOTransactionListViewDidAppear() {
    // Immediately reload KGO transaction list when view appeared
    let displayLoading: Bool = IEOTransactionStorage.shared.objects.isEmpty
    if displayLoading {
      self.profileVC?.displayLoading(text: "Loading Transactions...", animated: true)
    }
    self.reloadKyberGOTransactionList(completion: { [weak self] result in
      if displayLoading { self?.profileVC?.hideLoading() }
      switch result {
      case .success:
        let trans = IEOTransactionStorage.shared.objects
        self?.profileVC?.coordinatorUpdateTransactionList(trans)
      case .failure(let error):
        self?.profileVC?.displayError(error: error)
      }
    })
  }
}

// MARK: Confirm Buy Delegation
extension KGOHomePageCoordinator: KNConfirmTransactionViewControllerDelegate {
  func confirmTransactionViewController(_ controller: KNConfirmTransactionViewController, run event: KNConfirmTransactionViewEvent) {
    controller.dismiss(animated: true) {
      if case .confirm(let type) = event, case .buyTokenSale(let trans) = type {
        self.sendBuyTransaction(trans)
      }
    }
  }
}
