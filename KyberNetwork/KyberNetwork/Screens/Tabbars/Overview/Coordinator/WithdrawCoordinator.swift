//
//  WithdrawCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/2/21.
//

import Foundation
import Moya
import BigInt
import TrustCore
import Result

class WithdrawCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  let platform: String
  let balance: LendingBalance
  var balances: [String: Balance] = [:]
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate weak var gasPriceSelectVC: GasFeeSelectorPopupViewController?
  
  lazy var rootViewController: WithdrawConfirmPopupViewController = {
    let viewModel = WithdrawConfirmPopupViewModel(balance: self.balance)
    let controller = WithdrawConfirmPopupViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  lazy var withdrawViewController: WithdrawViewController = {
    let viewModel = WithdrawViewModel(platform: self.platform, session: self.session, balance: self.balance)
    let controller = WithdrawViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession, platfrom: String, balance: LendingBalance) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.platform = platfrom
    self.balance = balance
  }

  func start() {
    self.navigationController.present(self.rootViewController, animated: true, completion: nil)
  }

  func stop() {
    
  }
}

extension WithdrawCoordinator: WithdrawViewControllerDelegate {
  func withdrawViewController(_ controller: WithdrawViewController, run event: WithdrawViewEvent) {
    switch event {
    case .getWithdrawableAmount(platform: let platform, userAddress: let userAddress, tokenAddress: let tokenAddress):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getWithdrawableAmount(platform: platform, userAddress: userAddress, token: tokenAddress)) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let amount = json["amount"] as? String {
          self.withdrawViewController.coordinatorDidUpdateWithdrawableAmount(amount)
        } else {
          self.withdrawViewController.coodinatorFailUpdateWithdrawableAmount()
        }
      }
    case .buildWithdrawTx(platform: let platform, token: let token, amount: let amount, gasPrice: let gasPrice, useGasToken: let useGasToken):
      guard let blockchainProvider = self.session.externalProvider else {
        self.navigationController.showTopBannerView(message: "Watch wallet can not do this operation".toBeLocalised())
        return
      }
      controller.displayLoading()
      self.getLatestNonce { [weak self] (nonce) in
        guard let `self` = self else { return }
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
        provider.request(.buildWithdrawTx(platform: platform, userAddress: self.session.wallet.address.description, token: token, amount: amount, gasPrice: gasPrice, nonce: nonce, useGasToken: useGasToken)) { (result) in
          if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let dict = json["txObject"] as? [String: String] {
            guard let dataHexStr = dict["data"],
                  let to = dict["to"],
                  let valueHexString = dict["value"],
                  let value = BigInt(valueHexString.drop0x, radix: 16),
                  let gasPriceHexString = dict["gasPrice"],
                  let gasPrice = BigInt(gasPriceHexString.drop0x, radix: 16),
                  let gasLimitHexString = dict["gasLimit"],
                  let gasLimit = BigInt(gasLimitHexString.drop0x, radix: 16),
                  let nonceHexStr = dict["nonce"],
                  let nonce = Int(nonceHexStr.drop0x, radix: 16)
            else
            {
              controller.hideLoading()
              self.navigationController.showErrorTopBannerMessage(message: "Error decode response")
              return
            }
            if case let .real(account) = self.session.wallet.type {
              let transaction = SignTransaction(
                value: value,
                account: account,
                to: Address(string: to),
                nonce: nonce,
                data: Data(hex: dataHexStr.drop0x),
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                chainID: KNEnvironment.default.chainID
              )
              blockchainProvider.signTransactionData(from: transaction) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let signedData):
                  KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
                    controller.hideLoading()
                    switch sendResult {
                    case .success(let hash):
                      print(hash)
                      let tx = transaction.toTransaction(hash: hash, fromAddr: self.session.wallet.address.description, type: .withdraw)
                      self.session.addNewPendingTransaction(tx)
                      controller.dismiss(animated: true) {
                        self.openTransactionStatusPopUp(transaction: tx, token: token, amount: amount)
                      }
                    case .failure(let error):
                      self.navigationController.showTopBannerView(message: error.localizedDescription)
                    }
                  })
                case .failure:
                  controller.hideLoading()
                }
              }
            } else {
              controller.hideLoading()
              self.navigationController.showErrorTopBannerMessage(message: "Watch wallet is not supported")
              return
            }
          } else {
            controller.hideLoading()
          }
        }
      }
    case .updateGasLimit(platform: let platform, token: let token, amount: let amount, gasPrice: let gasPrice, useGasToken: let useGasToken):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.buildWithdrawTx(platform: platform, userAddress: self.session.wallet.address.description, token: token, amount: amount, gasPrice: gasPrice, nonce: 0, useGasToken: useGasToken)) { [weak self] (result) in
        guard let `self` = self else { return }
        if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let txObj = json["txObject"] as? [String: String], let gasLimitString = txObj["gasLimit"], let gasLimit = BigInt(gasLimitString.drop0x, radix: 16) {
          self.withdrawViewController.coordinatorDidUpdateGasLimit(gasLimit)
        } else {
          self.withdrawViewController.coordinatorFailUpdateGasLimit()
        }
      }
    case .checkAllowance(tokenAddress: let tokenAddress):
      guard let provider = self.session.externalProvider, let address = Address(string: tokenAddress) else {
        return
      }
      provider.getAllowance(tokenAddress: address) { [weak self] getAllowanceResult in
        guard let `self` = self else { return }
        switch getAllowanceResult {
        case .success(let res):
          self.withdrawViewController.coordinatorDidUpdateAllowance(token: tokenAddress, allowance: res)
        case .failure:
          self.withdrawViewController.coordinatorDidFailUpdateAllowance(token: tokenAddress)
        }
      }
    case .sendApprove(tokenAddress: let tokenAddress, remain: let remain, symbol: let symbol):
      let vc = ApproveTokenViewController(viewModel: ApproveTokenViewModelForTokenAddress(address: tokenAddress, remain: remain, state: false, symbol: symbol))
      vc.delegate = self
      self.withdrawViewController.present(vc, animated: true, completion: nil)
    case .openGasPriceSelect(gasLimit: let gasLimit, selectType: let selectType):
      let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: selectType, currentRatePercentage: 3, isUseGasToken: self.isAccountUseGasToken(), isContainSlippageSection: false)
      viewModel.updateGasPrices(
        fast: KNGasCoordinator.shared.fastKNGas,
        medium: KNGasCoordinator.shared.standardKNGas,
        slow: KNGasCoordinator.shared.lowKNGas,
        superFast: KNGasCoordinator.shared.superFastKNGas
      )

      let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
      vc.delegate = self
      self.withdrawViewController.present(vc, animated: true, completion: nil)
      self.gasPriceSelectVC = vc
    }
  }
  
  func getLatestNonce(completion: @escaping (Int) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getTransactionCount { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }

  fileprivate func openTransactionStatusPopUp(transaction: Transaction, token: String? = nil, amount: String? = nil) {
    let trans = KNTransaction.from(transaction: transaction)
    let controller = KNTransactionStatusPopUp(transaction: trans)
    controller.delegate = self
    if let wrappedToken = token, let unwrappedAmount = amount, let tokenData = KNSupportedTokenStorage.shared.getTokenWith(address: wrappedToken) {
      let amountString = BigInt(unwrappedAmount)?.string(decimals: tokenData.decimals, minFractionDigits: 0, maxFractionDigits: tokenData.decimals)
      controller.withdrawAmount = amountString
      controller.withdrawTokenSym = tokenData.symbol.uppercased()
    }
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension WithdrawCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    switch action {
    case .transfer:
      self.openSendTokenView()
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
    case .speedUp(let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .backToInvest:
      self.navigationController.popToRootViewController(animated: true)
    default:
      break
    }
  }

  fileprivate func openTransactionSpeedUpViewController(transaction: Transaction) {
    let viewModel = SpeedUpCustomGasSelectViewModel(transaction: transaction)
    let controller = SpeedUpCustomGasSelectViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    navigationController.present(controller, animated: true)
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: Transaction) {
    let viewModel = KNConfirmCancelTransactionViewModel(transaction: transaction)
    let confirmPopup = KNConfirmCancelTransactionPopUp(viewModel: viewModel)
    confirmPopup.delegate = self
    self.navigationController.present(confirmPopup, animated: true, completion: nil)
  }

  fileprivate func openSendTokenView() {
    if let topVC = self.navigationController.topViewController, topVC is KSendTokenViewController { return }
    if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
      let from: TokenObject = {
        return self.session.tokenStorage.ethToken
      }()
      let coordinator = KNSendTokenViewCoordinator(
        navigationController: self.navigationController,
        session: self.session,
        balances: self.balances,
        from: from
      )
      coordinator.start()
    } else {
      let message = NSLocalizedString("Please wait for other transactions to be mined before making a transfer", comment: "")
      self.navigationController.showWarningTopBannerMessage(
        with: "",
        message: message,
        time: 2.0
      )
    }
  }
  
  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.id, txHash == txID {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

extension WithdrawCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .done(let transaction, let newValue):
      let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
      self.sendSpeedUpSwapTransactionFor(transaction: transaction, availableTokens: tokenObjects, newPrice: newValue)
    case .invaild:
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "your.gas.must.be.10.percent.higher".toBeLocalised(),
        time: 1.5
      )
    }
  }

  fileprivate func sendSpeedUpSwapTransactionFor(transaction: Transaction, availableTokens: [TokenObject], newPrice: BigInt) {
    guard let provider = self.session.externalProvider else {
      return
    }
    guard let nouce = Int(transaction.nonce) else { return }
    guard let localizedOperation = transaction.localizedOperations.first else { return }
    guard let filteredToken = availableTokens.first(where: { (token) -> Bool in
      return token.symbol == localizedOperation.symbol
    }) else { return }
    let amount: BigInt = {
      return transaction.value.amountBigInt(decimals: localizedOperation.decimals) ?? BigInt(0)
    }()
    let gasLimit: BigInt = {
      return transaction.gasUsed.amountBigInt(units: .wei) ?? BigInt(0)
    }()
    provider.getTransactionByHash(transaction.id) { [weak self] (pendingTx, _) in
      guard let `self` = self else { return }
      if let fetchedTx = pendingTx, !fetchedTx.input.isEmpty {
        provider.speedUpSwapTransaction(
          for: filteredToken,
          amount: amount,
          nonce: nouce,
          data: fetchedTx.input,
          gasPrice: newPrice,
          gasLimit: gasLimit) { sendResult in
          switch sendResult {
          case .success(let txHash):
            let tx = transaction.convertToSpeedUpTransaction(newHash: txHash, newGasPrice: newPrice.displayRate(decimals: 0).removeGroupSeparator())
            self.session.updatePendingTransactionWithHash(hashTx: transaction.id, ultiTransaction: tx, state: .speedingUp, completion: {
              self.openTransactionStatusPopUp(transaction: tx)
            })
          case .failure:
            KNNotificationUtil.postNotification(
              for: kTransactionDidUpdateNotificationKey,
              object: nil,
              userInfo: [Constants.transactionIsCancel: TransactionType.speedup]
            )
          }
        }
      }
    }
  }
}

extension WithdrawCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: Transaction) {
    self.didConfirmTransfer(transaction)
  }

  fileprivate func didConfirmTransfer(_ transaction: Transaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    guard let unconfirmTx = transaction.makeCancelTransaction() else {
      return
    }
    provider.speedUpTransferTransaction(transaction: unconfirmTx, completion: { [weak self] sendResult in
      guard let `self` = self else { return }
      switch sendResult {
      case .success(let txHash):
        let tx: Transaction = unconfirmTx.toTransaction(
          wallet: self.session.wallet,
          hash: txHash,
          nounce: provider.minTxCount - 1,
          type: .cancel
        )
        self.session.updatePendingTransactionWithHash(hashTx: transaction.id, ultiTransaction: tx, completion: {
          self.openTransactionStatusPopUp(transaction: tx)
        })
      case .failure:
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: nil,
          userInfo: [Constants.transactionIsCancel: TransactionType.cancel]
        )
      }
    })
  }
}

extension WithdrawCoordinator: ApproveTokenViewControllerDelegate {
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool) {
    self.navigationController.displayLoading()
    guard let provider = self.session.externalProvider, let gasTokenAddress = Address(string: address) else {
      return
    }
    provider.sendApproveERCTokenAddress(
      for: gasTokenAddress,
      value: BigInt(2).power(256) - BigInt(1),
      gasPrice: KNGasCoordinator.shared.defaultKNGas) { approveResult in
      self.navigationController.hideLoading()
      switch approveResult {
      case .success:
        self.withdrawViewController.coordinatorSuccessApprove(token: address)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.localizedDescription,
          time: 1.5
        )
        self.withdrawViewController.coordinatorFailApprove(token: address)
      }
    }
  }

  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt) {
    
  }
}

extension WithdrawCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.withdrawViewController.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed:
      self.navigationController.showBottomBannerView(
        message: "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised(),
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .minRatePercentageChanged(let percent):
      break
    case .useChiStatusChanged(let status):
      guard let provider = self.session.externalProvider else {
        return
      }
      if self.isApprovedGasToken() {
        self.saveUseGasTokenState(status)
        self.withdrawViewController.coordinatorUpdateIsUseGasToken(status)
        return
      }
      if status {
        var gasTokenAddressString = ""
        if KNEnvironment.default == .ropsten {
          gasTokenAddressString = "0x0000000000b3F879cb30FE243b4Dfee438691c04"
        } else {
          gasTokenAddressString = "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c"
        }
        guard let tokenAddress = Address(string: gasTokenAddressString) else {
          return
        }
        provider.getAllowance(tokenAddress: tokenAddress) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let res):
            if res.isZero {
              let viewModel = ApproveTokenViewModelForTokenAddress(address: gasTokenAddressString, remain: res, state: status, symbol: "CHI")
              let viewController = ApproveTokenViewController(viewModel: viewModel)
              viewController.delegate = self
              self.navigationController.present(viewController, animated: true, completion: nil)
            } else {
              self.saveUseGasTokenState(status)
              self.withdrawViewController.coordinatorUpdateIsUseGasToken(status)
            }
          case .failure(let error):
            self.navigationController.showErrorTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: error.localizedDescription,
              time: 1.5
            )
            self.withdrawViewController.coordinatorUpdateIsUseGasToken(!status)
          }
        }
      } else {
        self.withdrawViewController.coordinatorUpdateIsUseGasToken(!status)
      }
    default:
      break
    }
  }
  
  fileprivate func isApprovedGasToken() -> Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data.keys.contains(self.session.wallet.address.description)
  }
  
  fileprivate func saveUseGasTokenState(_ state: Bool) {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    }
    data[self.session.wallet.address.description] = state
    UserDefaults.standard.setValue(data, forKey: Constants.useGasTokenDataKey)
  }
  
  fileprivate func isAccountUseGasToken() -> Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data[self.session.wallet.address.description] ?? false
  }
}

extension WithdrawCoordinator: WithdrawConfirmPopupViewControllerDelegate {
  func withdrawConfirmPopupViewControllerDidSelectFirstButton(_ controller: WithdrawConfirmPopupViewController) {
    controller.dismiss(animated: true) {
      self.navigationController.present(self.withdrawViewController, animated: true, completion: {
        self.withdrawViewController.coordinatorUpdateIsUseGasToken(self.isAccountUseGasToken())
      })
    }
  }
  
  func withdrawConfirmPopupViewControllerDidSelectSecondButton(_ controller: WithdrawConfirmPopupViewController) {
    controller.dismiss(animated: true) {
      
    }
  }
  
  
}
