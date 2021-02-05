//
//  EarnCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/26/21.
//

import Foundation
import Moya
import BigInt
import Result

class EarnCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var lendingTokens: [TokenData] = []
  var balances: [String: Balance] = [:]
  
  private(set) var session: KNSession
  fileprivate var historyCoordinator: KNHistoryCoordinator?
  
  lazy var rootViewController: EarnMenuViewController = {
    let viewModel = EarnMenuViewModel()
    let viewController = EarnMenuViewController(viewModel: viewModel)
    viewController.delegate = self
    return viewController
  }()
  
  fileprivate weak var earnViewController: EarnViewController?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.navigationController.viewControllers = [self.rootViewController]
  }
  
  func start() {
    //TODO: pesist token data in to disk then load into memory
    self.getLendingOverview()
//    self.rootViewController.coordinatorDidUpdateLendingToken(self.lendingTokens)
  }

  func stop() {
    
  }

  // MARK: Bussiness code
  func getLendingOverview() {
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getLendingOverview) { [weak self] (result) in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["result"] as? [JSONDictionary] {
            let addresses = result.map { (dict) -> String in
              return dict["address"] as? String ?? ""
            }.map { $0.lowercased() }
            //Find tokens object with loaded address
            //TODO: improve with struct data type
            var lendingTokensData: [TokenData] = []
            let lendingTokens = self.session.tokenStorage.findTokensWithAddresses(addresses: addresses)
            //Get token decimal to init token data
            lendingTokens.forEach { (token) in
              let tokenDict = result.first { (tokenDict) -> Bool in
                if let tokenAddress = tokenDict["address"] as? String {
                  return token.contract.lowercased() == tokenAddress.lowercased()
                } else {
                  return false
                }
              }
              var platforms: [LendingPlatformData] = []
              if let platformDicts = tokenDict?["overview"] as? [JSONDictionary] {
                platformDicts.forEach { (platformDict) in
                  let platform = LendingPlatformData(
                    name: platformDict["name"] as? String ?? "",
                    supplyRate: platformDict["supplyRate"] as? Double ?? 0.0,
                    stableBorrowRate: platformDict["stableBorrowRate"] as? Double ?? 0.0,
                    variableBorrowRate: platformDict["variableBorrowRate"] as? Double ?? 0.0,
                    distributionSupplyRate: platformDict["distributionSupplyRate"] as? Double ?? 0.0,
                    distributionBorrowRate: platformDict["distributionBorrowRate"] as? Double ?? 0.0
                  )
                  platforms.append(platform)
                }
              }
              let tokenData = TokenData(address: token.contract, name: token.name, symbol: token.symbol, decimals: token.decimals, lendingPlatforms: platforms)
              lendingTokensData.append(tokenData)
            }
            self.lendingTokens = lendingTokensData
            self.rootViewController.coordinatorDidUpdateLendingToken(self.lendingTokens)
          } else {
            self.getLendingOverview()
          }
        }
      }
    }
  }
  
  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.earnViewController?.coordinatorUpdateTokenBalance(self.balances)
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
    self.balances = [:]
  }
  
  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.id, txHash == txID {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

extension EarnCoordinator: EarnMenuViewControllerDelegate {
  func earnMenuViewControllerDidSelectToken(controller: EarnMenuViewController, token: TokenData) {
    let viewModel = EarnViewModel(data: token, wallet: self.session.wallet)
    let controller = EarnViewController(viewModel: viewModel)
    controller.delegate = self
    self.earnViewController = controller
    self.earnViewController?.coordinatorUpdateTokenBalance(self.balances)
    self.navigationController.pushViewController(controller, animated: true)
  }
}

extension EarnCoordinator: EarnViewControllerDelegate {
  func earnViewController(_ controller: EarnViewController, run event: EarnViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let selectType):
      let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: false, gasLimit: gasLimit, selectType: selectType)
      viewModel.updateGasPrices(
        fast: KNGasCoordinator.shared.fastKNGas,
        medium: KNGasCoordinator.shared.standardKNGas,
        slow: KNGasCoordinator.shared.lowKNGas,
        superFast: KNGasCoordinator.shared.superFastKNGas
      )

      let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .getGasLimit(let platform, let src, let dest, let amount, let minDestAmount, let gasPrice):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.buildSwapAndDepositTx(
                        lendingPlatform: platform,
                        userAddress: self.session.wallet.address.description,
                        src: src,
                        dest: dest,
                        srcAmount: amount,
                        minDestAmount: minDestAmount,
                        gasPrice: gasPrice,
                        nonce: 0,
                        hint: "",
                        useGasToken: false
      )) { (result) in
        if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let txObj = json["txObject"] as? [String: String], let gasLimitString = txObj["gasLimit"], let gasLimit = BigInt(gasLimitString.drop0x, radix: 16) {
          self.earnViewController?.coordinatorDidUpdateGasLimit(gasLimit, platform: platform, tokenAdress: src)
        } else {
          self.earnViewController?.coordinatorFailUpdateGasLimit()
        }
      }
    case .buildTx(let platform, let src, let dest, let amount, let minDestAmount, let gasPrice):
      self.navigationController.displayLoading()
      self.getLatestNonce { [weak self] (nonce) in
        guard let `self` = self else { return }
        self.buildTx(
          lendingPlatform: platform,
          userAddress: self.session.wallet.address.description,
          src: src,
          dest: dest,
          srcAmount: amount,
          minDestAmount: minDestAmount,
          gasPrice: gasPrice,
          nonce: nonce
        ) { (result) in
          self.navigationController.hideLoading()
          switch result {
          case .success(let txObj):
            self.earnViewController?.coordinatorDidUpdateSuccessTxObject(txObject: txObj)
          case .failure(let error):
            self.earnViewController?.coordinatorFailUpdateTxObject(error: error)
          }
        }
      }
    case .confirmTx(let token, let platform, let amount, let gasPrice, let gasLimit, let transaction):
      let viewModel = EarnConfirmViewModel(platform: platform, token: token, amount: amount, gasPrice: gasPrice, gasLimit: gasLimit, transaction: transaction)
      let controller = EarnConfirmViewController(viewModel: viewModel)
      controller.delegate = self
      self.navigationController.present(controller, animated: true, completion: nil)
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
  
  func buildTx(lendingPlatform: String, userAddress: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, nonce: Int, completion: @escaping (Result<[String: String], AnyError>) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.buildSwapAndDepositTx(
                      lendingPlatform: lendingPlatform,
                      userAddress: self.session.wallet.address.description,
                      src: src,
                      dest: dest,
                      srcAmount: srcAmount,
                      minDestAmount: minDestAmount,
                      gasPrice: gasPrice,
                      nonce: nonce,
                      hint: "",
                      useGasToken: false
    )) { (result) in
      switch result {
      case .success(let resp):
        if let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let txObj = json["txObject"] as? [String: String] {
          completion(.success(txObj))
        } else {
          completion(.failure(AnyError(NSError(domain: "Can not decode data", code: 404, userInfo: nil))))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

extension EarnCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.earnViewController?.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed:
      self.navigationController.showBottomBannerView(
        message: "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised(),
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    default:
      break
    }
  }
}

extension EarnCoordinator: EarnConfirmViewControllerDelegate {
  func earnConfirmViewController(_ controller: EarnConfirmViewController, didConfirm transaction: SignTransaction, amount: String, netAPY: String, platform: LendingPlatformData) {
    guard let provider = self.session.externalProvider else {
      self.navigationController.showTopBannerView(message: "Watch wallet can not do this operation".toBeLocalised())
      return
    }
    self.navigationController.displayLoading()
    provider.signTransactionData(from: transaction) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let signedData):
        KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
          self.navigationController.hideLoading()
          switch sendResult {
          case .success(let hash):
            print(hash)
            let tx = transaction.toTransaction(hash: hash, fromAddr: self.session.wallet.address.description)
            self.session.addNewPendingTransaction(tx)
            self.openTransactionStatusPopUp(transaction: tx)
            self.transactionStatusVC?.earnAmountString = amount
            self.transactionStatusVC?.netAPYEarnString = netAPY
            self.transactionStatusVC?.earnPlatform = platform
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.localizedDescription)
          }
        })
      case .failure:
        self.navigationController.hideLoading()
      }
    }
  }

  fileprivate func openTransactionStatusPopUp(transaction: Transaction) {
    let trans = KNTransaction.from(transaction: transaction)
    let controller = KNTransactionStatusPopUp(transaction: trans)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension EarnCoordinator: KNTransactionStatusPopUpDelegate {
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
        guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description), let token = self.session.tokenStorage.tokens.first(where: { return $0.symbol == destToken }) else {
          return self.session.tokenStorage.ethToken
        }
        return token
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
}

extension EarnCoordinator: SpeedUpCustomGasSelectDelegate {
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

extension EarnCoordinator: KNConfirmCancelTransactionPopUpDelegate {
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
