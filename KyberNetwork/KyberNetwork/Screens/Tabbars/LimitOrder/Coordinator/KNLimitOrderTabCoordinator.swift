// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore
import Result
import Moya
import APIKit

protocol KNLimitOrderTabCoordinatorDelegate: class {
  func limitOrderTabCoordinatorDidSelectWallet(_ wallet: KNWalletObject)
  func limitOrderTabCoordinatorRemoveWallet(_ wallet: Wallet)
  func limitOrderTabCoordinatorDidSelectAddWallet()
  func limitOrderTabCoordinatorDidSelectPromoCode()
}

class KNLimitOrderTabCoordinator: Coordinator {

  let navigationController: UINavigationController
  var session: KNSession
  var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true
  var coordinators: [Coordinator] = []

  weak var delegate: KNLimitOrderTabCoordinatorDelegate?

  fileprivate var balances: [String: Balance] = [:]

  fileprivate var historyCoordinator: KNHistoryCoordinator?
  fileprivate var searchTokensViewController: KNSearchTokenViewController?
  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?

  fileprivate var confirmVC: KNConfirmLimitOrderViewController?
  fileprivate var manageOrdersVC: KNManageOrdersViewController?

  lazy var rootViewController: KNCreateLimitOrderViewController = {
    let (from, to): (TokenObject, TokenObject) = {
      let address = self.session.wallet.address.description
      let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: address)
      if let dest = destToken, let from = KNSupportedTokenStorage.shared.ptToken {
        let to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == dest.uppercased() }) ?? KNSupportedTokenStorage.shared.ethToken
        return (from, to)
      }
      return (KNSupportedTokenStorage.shared.kncToken, KNSupportedTokenStorage.shared.ethToken)
    }()
    let viewModel = KNCreateLimitOrderViewModel(
      wallet: self.session.wallet,
      from: from,
      to: to,
      supportedTokens: tokens
    )
    let controller = KNCreateLimitOrderViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

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
  }
}

// MARK: Update from app coordinator
extension KNLimitOrderTabCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
    let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
    self.rootViewController.coordinatorDidUpdatePendingTransactions(pendingTrans)
    if self.navigationController.viewControllers.first(where: { $0 is KNHistoryViewController }) == nil {
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController,
        session: self.session
      )
    }
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
    self.historyCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.searchTokensViewController?.updateBalances(otherTokensBalance)
  }

  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    if let eth = self.tokens.first(where: { $0.isETH }) {
      self.balances[eth.contract] = ethBalance
      self.searchTokensViewController?.updateBalances([eth.contract: ethBalance])
      self.rootViewController.coordinatorUpdateTokenBalance([eth.contract: ethBalance])
    }
    self.sendTokenCoordinator?.coordinatorETHBalanceDidUpdate(ethBalance: ethBalance)
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.rootViewController.coordinatorTrackerRateDidUpdate()
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
  }

  func appCoordinatorUpdateExchangeTokenRates() {
    self.rootViewController.coordinatorUpdateProdCachedRates()
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    let supportedTokens = KNSupportedTokenStorage.shared.supportedTokens
    self.tokens = supportedTokens
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.searchTokensViewController?.updateListSupportedTokens(supportedTokens)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
    self.rootViewController.coordinatorDidUpdatePendingTransactions(transactions)
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }
}

extension KNLimitOrderTabCoordinator: KNCreateLimitOrderViewControllerDelegate {
  func kCreateLimitOrderViewController(_ controller: KNCreateLimitOrderViewController, run event: KNCreateLimitOrderViewEvent) {
    switch event {
    case .searchToken(let from, let to, let isSource):
      self.openSearchToken(from: from, to: to, isSource: isSource)
    case .estimateRate(let from, let to, let amount, let showWarning):
      self.updateEstimatedRate(from: from, to: to, amount: amount, showError: showWarning, completion: nil)
    case .submitOrder(let order):
      self.openConfirmOrder(order)
    case .manageOrders:
      var orders: [KNOrderObject] = []
      let tokenCount = self.tokens.count
      var account: Account!
      if case .real(let acc) = self.session.wallet.type { account = acc }
      for id in 0..<10 {
        let from = self.tokens[Int(arc4random() % UInt32(tokenCount))]
        let to = self.tokens[Int(arc4random() % UInt32(tokenCount))]
        let limitOrder = KNLimitOrder(
          from: from,
          to: to,
          account: account,
          sender: account.address,
          srcAmount: BigInt(arc4random() % 100 + 10) * BigInt(10).power(from.decimals),
          targetRate: BigInt(Double((arc4random() % 100 + 10)) / 50.0 * pow(10.0, Double(to.decimals))),
          fee: Int(arc4random() % 10 + 5),
          nonce: id
        )
        orders.append(KNOrderObject.getOrderObject(from: limitOrder))
      }
      if self.manageOrdersVC == nil {
        self.manageOrdersVC = KNManageOrdersViewController(
          viewModel: KNManageOrdersViewModel(orders: orders)
        )
        self.manageOrdersVC?.loadViewIfNeeded()
        self.manageOrdersVC?.delegate = self
      }
      self.navigationController.pushViewController(self.manageOrdersVC!, animated: true) {
        self.manageOrdersVC?.updateListOrders(orders)
      }
    default: break
    }
  }

  func kCreateLimitOrderViewController(_ controller: KNCreateLimitOrderViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    switch event {
    case .selectSendToken:
      self.openSendTokenView()
    case .selectAddWallet:
      self.openAddWalletView()
    case .select(let wallet):
      self.updateCurrentWallet(wallet)
    case .selectPromoCode:
      self.openPromoCodeView()
    case .selectAllTransactions:
      self.openHistoryTransactionsView()
    }
  }

  fileprivate func openConfirmOrder(_ order: KNLimitOrder) {
    self.confirmVC = KNConfirmLimitOrderViewController(order: order)
    self.confirmVC?.delegate = self
    self.confirmVC?.loadViewIfNeeded()
    self.navigationController.pushViewController(self.confirmVC!, animated: true)
  }

  fileprivate func signAndSendOrder(_ order: KNLimitOrder, completion: ((Bool) -> Void)?) {
    self.navigationController.displayLoading(text: "Checking".toBeLocalised(), animated: true)
    self.sendApprovedIfNeeded(order: order) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let isSuccess):
        if !isSuccess {
          self.navigationController.hideLoading()
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", comment: ""),
            message: "Can not send approve token request".toBeLocalised(),
            time: 1.5
          )
          completion?(false)
          return
        }
        self.navigationController.displayLoading(text: "Submitting order".toBeLocalised(), animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: {
          let result = self.session.keystore.signLimitOrder(order)
          self.navigationController.hideLoading()
          switch result {
          case .success:
            self.navigationController.showSuccessTopBannerMessage(
              with: NSLocalizedString("success", comment: ""),
              message: "Successfully signed the order data".toBeLocalised(),
              time: 1.5
            )
            self.rootViewController.coordinatorDoneSubmittingOrder(order)
            completion?(true)
          case .failure(let error):
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", comment: ""),
              message: "Can not sign your order, error: \(error.prettyError)".toBeLocalised(),
              time: 1.5
            )
            completion?(false)
          }
        })
      case .failure(let error):
        self.navigationController.hideLoading()
        self.navigationController.displayError(error: error)
        completion?(false)
      }
    }
  }

  fileprivate func sendApprovedIfNeeded(order: KNLimitOrder, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.session.externalProvider.getAllowanceLimitOrder(token: order.from) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let remain):
        if remain >= order.srcAmount {
          completion(.success(true))
        } else {
          self.sendApprovedTransaction(order: order, remain: remain, completion: completion)
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func sendApprovedTransaction(order: KNLimitOrder, remain: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.sendResetAllowanceIfNeeded(order: order, remain: remain) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let isSuccess):
        if isSuccess {
          self.session.externalProvider.sendApproveERCTokenLimitOrder(
            for: order.from,
            value: BigInt(2).power(255),
            gasPrice: KNGasCoordinator.shared.fastKNGas,
            completion: completion
          )
        } else {
          completion(.success(false))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func sendResetAllowanceIfNeeded(order: KNLimitOrder, remain: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if remain.isZero {
      completion(.success(true))
      return
    }
    self.session.externalProvider.sendApproveERCTokenLimitOrder(
      for: order.from,
      value: BigInt(0),
      gasPrice: KNGasCoordinator.shared.fastKNGas,
      completion: completion
    )
  }

  fileprivate func openPromoCodeView() {
    self.delegate?.limitOrderTabCoordinatorDidSelectPromoCode()
  }

  fileprivate func openAddWalletView() {
    self.delegate?.limitOrderTabCoordinatorDidSelectAddWallet()
  }

  fileprivate func updateCurrentWallet(_ wallet: KNWalletObject) {
    self.delegate?.limitOrderTabCoordinatorDidSelectWallet(wallet)
  }

  fileprivate func openHistoryTransactionsView() {
    self.historyCoordinator = nil
    self.historyCoordinator = KNHistoryCoordinator(
      navigationController: self.navigationController,
      session: self.session
    )
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator?.start()
  }

  fileprivate func openSearchToken(from: TokenObject, to: TokenObject, isSource: Bool) {
    self.isSelectingSourceToken = isSource
    self.tokens = KNSupportedTokenStorage.shared.supportedTokens
    self.searchTokensViewController = {
      let viewModel = KNSearchTokenViewModel(
        headerColor: KNAppStyleType.current.swapHeaderBackgroundColor,
        supportedTokens: self.tokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.searchTokensViewController!, animated: true)
    self.searchTokensViewController?.updateBalances(self.balances)
  }

  fileprivate func openSendTokenView() {
    if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
      self.sendTokenCoordinator = KNSendTokenViewCoordinator(
        navigationController: self.navigationController,
        session: self.session,
        balances: self.balances,
        from: self.session.tokenStorage.ethToken
      )
      self.sendTokenCoordinator?.start()
    } else {
      let message = NSLocalizedString("Please wait for other transactions to be mined before making a transfer", comment: "")
      self.navigationController.showWarningTopBannerMessage(
        with: "",
        message: message,
        time: 2.0
      )
    }
  }

  // Call contract to get estimate rate with src, dest, srcAmount
  fileprivate func updateEstimatedRate(from: TokenObject, to: TokenObject, amount: BigInt, showError: Bool, completion: ((Error?) -> Void)? = nil) {
    self.getExpectedExchangeRate(from: from, to: to, amount: amount) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        self.rootViewController.coordinatorDidUpdateEstimateRate(
          from: from,
          to: to,
          amount: amount,
          rate: data.0,
          slippageRate: data.1
        )
        completion?(nil)
      case .failure(let error):
        if showError {
          if case let err as APIKit.SessionTaskError = error.error, case .connectionError = err {
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: NSLocalizedString("please.check.your.internet.connection", value: "Please check your internet connection", comment: ""),
              time: 1.5
            )
          } else {
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: NSLocalizedString("can.not.update.exchange.rate", comment: "Can not update exchange rate"),
              time: 1.5
            )
          }
          self.rootViewController.coordinatorDidUpdateEstimateRate(
            from: from,
            to: to,
            amount: amount,
            rate: BigInt(0),
            slippageRate: BigInt(0)
          )
        }
        completion?(error)
      }
    }
  }

  fileprivate func getExpectedExchangeRate(from: TokenObject, to: TokenObject, amount: BigInt, completion: ((Result<(BigInt, BigInt), AnyError>) -> Void)? = nil) {
    if from == to {
      let rate = BigInt(10).power(from.decimals)
      let slippageRate = rate * BigInt(97) / BigInt(100)
      completion?(.success((rate, slippageRate)))
      return
    }
    self.session.externalProvider.getExpectedRate(
      from: from,
      to: to,
      amount: amount) { (result) in
        var estRate: BigInt = BigInt(0)
        var slippageRate: BigInt = BigInt(0)
        switch result {
        case .success(let data):
          estRate = data.0
          slippageRate = data.1
          estRate /= BigInt(10).power(18 - to.decimals)
          slippageRate /= BigInt(10).power(18 - to.decimals)
          completion?(.success((estRate, slippageRate)))
        case .failure(let error):
          completion?(.failure(error))
        }
    }
  }
}

extension KNLimitOrderTabCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidClose() {
    //    self.historyCoordinator = nil
  }
}

// MARK: Search token
extension KNLimitOrderTabCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.navigationController.popViewController(animated: true) {
      self.searchTokensViewController = nil
      if case .select(let token) = event {
        self.rootViewController.coordinatorUpdateSelectedToken(
          token,
          isSource: self.isSelectingSourceToken
        )
      }
    }
  }
}

extension KNLimitOrderTabCoordinator: KNManageOrdersViewControllerDelegate {
}

extension KNLimitOrderTabCoordinator: KNConfirmLimitOrderViewControllerDelegate {
  func confirmLimitOrderViewControllerDidBack() {
    self.confirmVC = nil
  }

  func confirmLimitOrderViewController(_ controller: KNConfirmLimitOrderViewController, order: KNLimitOrder) {
    self.signAndSendOrder(order) { [weak self] isSuccess in
      guard let `self` = self else { return }
      if isSuccess && self.confirmVC != nil {
        self.navigationController.popViewController(animated: true, completion: {
          self.confirmVC = nil
        })
      }
    }
  }
}
