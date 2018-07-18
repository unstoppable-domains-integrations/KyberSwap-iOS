// Copyright SIX DAY LLC. All rights reserved.

import Moya
import BigInt
import TrustKeystore
import TrustCore
import Result
import SafariServices

extension KGOHomePageCoordinator {
  internal func openBuy(object: IEOObject) {
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

  internal func sendBuyTransaction(_ transaction: IEODraftTransaction) {
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

  fileprivate func getContributorRemainingCap(userID: Int, contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    IEOProvider.shared.getContributorRemainingCap(
      contractAddress: contract,
      userID: userID,
      completion: completion
    )
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

  internal func showAlertUserNotSignIn() {
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
