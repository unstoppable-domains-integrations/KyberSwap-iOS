// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import BigInt
import TrustKeystore
import TrustCore
import Result
import SafariServices

enum IEOBuyTokenCoordinatorEvent {
  case stop
  case bought
  case openSignIn
}

protocol IEOBuyTokenCoordinatorDelegate: class {
  func ieoBuyTokenCoordinator(_ coordinator: IEOBuyTokenCoordinator, run event: IEOBuyTokenCoordinatorEvent)
}

class IEOBuyTokenCoordinator: Coordinator {

  var coordinators: [Coordinator] = []

  let navigationController: UINavigationController
  fileprivate(set) var session: KNSession
  fileprivate(set) var object: IEOObject?

  fileprivate(set) var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens

  weak var delegate: IEOBuyTokenCoordinatorDelegate?

  fileprivate var rootViewController: IEOBuyTokenViewController?

  private(set) var setGasPriceVC: KNSetGasPriceViewController?
  private(set) var profileVC: IEOProfileViewController?

  lazy var searchTokensViewController: KNSearchTokenViewController = {
    let viewModel = KNSearchTokenViewModel(supportedTokens: self.tokens)
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession,
    object: IEOObject?
    ) {
    self.navigationController = navigationController
    self.session = session
    self.object = object
  }

  func start() {
    guard let wallet = KNWalletStorage.shared.wallets.first(where: {
      $0.address.lowercased() == self.session.wallet.address.description.lowercased()
    }), let object = self.object else { return }
    let viewModel = IEOBuyTokenViewModel(to: object, walletObject: wallet)
    self.rootViewController = IEOBuyTokenViewController(viewModel: viewModel)
    self.rootViewController?.loadViewIfNeeded()
    self.rootViewController?.delegate = self
    self.navigationController.pushViewController(self.rootViewController!, animated: true)
  }

  func updateSession(_ session: KNSession, object: IEOObject) {
    self.session = session
    self.object = object
  }

  func coordinatorDidUpdateEstRate(for object: IEOObject, rate: BigInt) {
    self.rootViewController?.coordinatorDidUpdateEstRate(for: object, rate: rate)
  }

  func coordinatorDidUpdateWalletObjects() {
    self.rootViewController?.coordinatorDidUpdateWalletObjects()
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController = nil
    }
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
          guard let `self` = self else { return }
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              self.delegate?.ieoBuyTokenCoordinator(self, run: .bought)
              return
            } catch let error {
              NSLog("----KyberGO: Add transaction failed with error: \(error.prettyError)----")
            }
          case .failure(let error):
            NSLog("----KyberGO: Add transaction failed with error: \(error.prettyError)----")
          }
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
            self.addTransactionRequest(draftTx: draftTx, hash: hash)
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
      self.delegate?.ieoBuyTokenCoordinator(self, run: .openSignIn)
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func getContributorRemainingCap(userID: Int, contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    IEOProvider.shared.getContributorRemainingCap(
      contractAddress: contract,
      userID: userID,
      completion: completion
    )
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
}

extension IEOBuyTokenCoordinator: IEOBuyTokenViewControllerDelegate {
  func ieoBuyTokenViewController(_ controller: IEOBuyTokenViewController, run event: IEOBuyTokenViewEvent) {
    switch event {
    case .close:
      self.delegate?.ieoBuyTokenCoordinator(self, run: .stop)
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
    case .selectBuyToken:
      self.tokens = KNSupportedTokenStorage.shared.supportedTokens
      self.searchTokensViewController.updateListSupportedTokens(self.tokens)
      self.navigationController.present(self.searchTokensViewController, animated: true, completion: nil)
    case .buy(let transaction):
      guard let userID = IEOUserStorage.shared.user?.userID else {
        self.showAlertUserNotSignIn()
        return
      }
      transaction.update(userID: userID)
      self.openConfirmView(for: transaction)
    default: break
    }
  }
}

// MARK: Search token
extension IEOBuyTokenCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.searchTokensViewController.dismiss(animated: true) {
      if case .select(let token) = event {
        self.rootViewController?.coordinatorUpdateBuyToken(token)
      }
    }
  }
}

// MARK: Set Gas View Delegation
extension IEOBuyTokenCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      self.rootViewController?.coordinatorBuyTokenDidUpdateGasPrice(gasPrice)
      self.setGasPriceVC = nil
    }
  }
}

// MARK: Confirm Buy Delegation
extension IEOBuyTokenCoordinator: KNConfirmTransactionViewControllerDelegate {
  func confirmTransactionViewController(_ controller: KNConfirmTransactionViewController, run event: KNConfirmTransactionViewEvent) {
    controller.dismiss(animated: true) {
      if case .confirm(let type) = event, case .buyTokenSale(let trans) = type {
        self.sendBuyTransaction(trans)
      }
    }
  }
}
