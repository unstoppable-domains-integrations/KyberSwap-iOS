// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore

class KNBalanceCoordinator {

  fileprivate let session: KNSession

  fileprivate var fetchETHBalanceTimer: Timer?
  fileprivate var isFetchingETHBalance: Bool = false
  var ethBalance: Balance = Balance(value: BigInt(0))

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false
  var otherTokensBalance: [String: Balance] = [:]

  var totalBalanceInUSD: BigInt {
    let rates = KNRateCoordinator.shared.usdRates
    var value = BigInt(0)
    if let ethRate = rates.first(where: { $0.source == "ETH" }) {
      value = ethRate.rate * ethBalance.value
    }
    let supportedTokens = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
    for token in supportedTokens {
      if let rate = rates.first(where: { $0.source == token.symbol }), let balance = otherTokensBalance[token.address] {
        value += rate.rate * balance.value
      }
    }
    return value
  }

  var totalBalanceInETH: BigInt {
    let rates = KNRateCoordinator.shared.tokenRates
    var value = ethBalance.value
    let supportedTokens = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
    for token in supportedTokens {
      if let rate = rates.first(where: { $0.source == token.symbol && $0.dest == "ETH" }), let balance = otherTokensBalance[token.address] {
        value += rate.rate * balance.value / BigInt(EthereumUnit.ether.rawValue)
      }
    }
    return value
  }

  init(session: KNSession) {
    self.session = session
  }

  func resume() {
    fetchETHBalanceTimer?.invalidate()
    isFetchingETHBalance = false
    fetchETHBalance(nil)

    fetchETHBalanceTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.defaultLoadingInterval,
      target: self,
      selector: #selector(self.fetchETHBalance(_:)),
      userInfo: nil,
      repeats: true
    )

    fetchOtherTokensBalanceTimer?.invalidate()
    isFetchingOtherTokensBalance = false
    fetchOtherTokensBalance(nil)

    fetchETHBalanceTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.defaultLoadingInterval,
      target: self,
      selector: #selector(self.fetchOtherTokensBalance(_:)),
      userInfo: nil,
      repeats: true
    )
  }

  func pause() {
    fetchETHBalanceTimer?.invalidate()
    fetchETHBalanceTimer = nil
    isFetchingETHBalance = true

    fetchOtherTokensBalanceTimer?.invalidate()
    fetchOtherTokensBalanceTimer = nil
    isFetchingOtherTokensBalance = true
  }

  func exit() {
    pause()
  }

  @objc func fetchETHBalance(_ sender: Timer?) {
    if isFetchingETHBalance { return }
    isFetchingETHBalance = true
    self.session.externalProvider.getETHBalance { [weak self] result in
      guard let `self` = self else { return }
      self.isFetchingETHBalance = false
      switch result {
      case .success(let balance):
        self.ethBalance = balance
        KNNotificationUtil.postNotification(for: kETHBalanceDidUpdateNotificationKey)
      case .failure(let error):
        NSLog("Load ETH Balance failed with error: \(error.description)")
      }
    }
  }

  @objc func fetchOtherTokensBalance(_ sender: Timer?) {
    if isFetchingOtherTokensBalance { return }
    isFetchingOtherTokensBalance = true
    let tokens = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
    let group = DispatchGroup()
    for token in tokens {
      if let contractAddress = Address(string: token.address), token.symbol != "ETH" {
        group.enter()
        self.session.externalProvider.getTokenBalance(for: contractAddress, completion: { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let bigInt):
            let balance = Balance(value: bigInt)
            self.otherTokensBalance[token.address] = balance
            NSLog("Done loading \(token.symbol) balance: \(balance.amountFull)")
          case .failure(let error):
            NSLog("Load \(token.symbol) balance failed with error: \(error.description)")
          }
          group.leave()
        })
      }
    }
    // notify when all load balances are done
    group.notify(queue: .main) {
      self.isFetchingOtherTokensBalance = false
      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
    }
  }
}
