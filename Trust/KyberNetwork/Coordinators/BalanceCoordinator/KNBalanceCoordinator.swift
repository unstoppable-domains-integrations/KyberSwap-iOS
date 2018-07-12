// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore

class KNBalanceCoordinator {

  fileprivate var session: KNSession!
  fileprivate var ethToken: TokenObject!

  fileprivate var fetchETHBalanceTimer: Timer?
  fileprivate var isFetchingETHBalance: Bool = false
  var ethBalance: Balance = Balance(value: BigInt(0))

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false
  var otherTokensBalance: [String: Balance] = [:]

  var totalBalanceInUSD: BigInt {
    let balanceValue: BigInt = {
      var value = BigInt(0)
      if self.ethToken != nil, let ethRate = KNRateCoordinator.shared.usdRate(for: self.ethToken) {
        value = ethRate.rate * ethBalance.value / BigInt(EthereumUnit.ether.rawValue)
      }
      let tokens = self.session.tokenStorage.tokens
      for token in tokens {
        if let balance = otherTokensBalance[token.contract], !balance.value.isZero, let rate = KNRateCoordinator.shared.usdRate(for: token) {
          value += rate.rate * balance.value / BigInt(10).power(token.decimals)
        }
      }
      return value
    }()
    return balanceValue
  }

  var totalBalanceInETH: BigInt {
    let balanceValue: BigInt = {
      var value = self.ethBalance.value
      if self.ethToken == nil { return value }

      let tokenObjects = self.session.tokenStorage.tokens

      for tokenObj in tokenObjects {
        if let balance = otherTokensBalance[tokenObj.contract], !balance.value.isZero, let rate = KNRateCoordinator.shared.getRate(from: tokenObj, to: self.ethToken) {
          value += rate.rate * balance.value / BigInt(10).power(tokenObj.decimals)
        }
      }
      return value
    }()
    return balanceValue
  }

  deinit {
    self.exit()
    self.session = nil
    self.ethToken = nil
  }

  init(session: KNSession) {
    self.session = session
    self.ethToken = session.tokenStorage.ethToken
    self.updateBalancesFromLocalData()
  }

  func restartNewSession(_ session: KNSession) {
    self.session = session
    self.ethToken = session.tokenStorage.ethToken
    self.ethBalance = Balance(value: BigInt(0))
    self.otherTokensBalance = [:]
    self.updateBalancesFromLocalData()
    self.resume()
  }

  fileprivate func updateBalancesFromLocalData() {
    let tokens = self.session.tokenStorage.tokens
    tokens.forEach { token in
      if token.isETH {
        self.ethBalance = Balance(value: token.valueBigInt)
      } else {
        self.otherTokensBalance[token.contract] = Balance(value: token.valueBigInt)
      }
    }
  }

  func resume() {
    fetchETHBalanceTimer?.invalidate()
    isFetchingETHBalance = false
    fetchETHBalance(nil)

    fetchETHBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchETHBalance(timer)
    })

    fetchOtherTokensBalanceTimer?.invalidate()
    isFetchingOtherTokensBalance = false
    fetchOtherTokensBalance(nil)

    fetchOtherTokensBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchOtherTokensBalance(timer)
    })
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
    self.session = nil
    self.ethToken = nil
  }

  @objc func fetchETHBalance(_ sender: Timer?) {
    if isFetchingETHBalance { return }
    isFetchingETHBalance = true
    let currentWallet = self.session.wallet
    let address = self.ethToken.address
    DispatchQueue.global(qos: .background).async {
      if self.session == nil { return }
      self.session.externalProvider.getETHBalance { [weak self] result in
        DispatchQueue.main.async {
          guard let `self` = self else { return }
          if self.session == nil || currentWallet != self.session.wallet { return }
          self.isFetchingETHBalance = false
          switch result {
          case .success(let balance):
            self.ethBalance = balance
            self.session.tokenStorage.updateBalance(for: address, balance: balance.value)
            KNNotificationUtil.postNotification(for: kETHBalanceDidUpdateNotificationKey)
          case .failure(let error):
            NSLog("Load ETH Balance failed with error: \(error.description)")
          }
        }
      }
    }
  }

  @objc func fetchOtherTokensBalance(_ sender: Timer?) {
    if isFetchingOtherTokensBalance { return }
    isFetchingOtherTokensBalance = true
    let tokenContracts = self.session.tokenStorage.tokens.filter({ return !$0.isETH }).map({ $0.contract })
    let currentWallet = self.session.wallet
    let group = DispatchGroup()
    for contract in tokenContracts {
      if let contractAddress = Address(string: contract) {
        group.enter()
        DispatchQueue.global(qos: .background).async {
          if self.session == nil { group.leave(); return }
          self.session.externalProvider.getTokenBalance(for: contractAddress, completion: { [weak self] result in
            DispatchQueue.main.async {
              guard let `self` = self else { group.leave(); return }
              if self.session == nil || currentWallet != self.session.wallet { group.leave(); return }
              switch result {
              case .success(let bigInt):
                let balance = Balance(value: bigInt)
                self.otherTokensBalance[contract] = balance
                self.session.tokenStorage.updateBalance(for: contractAddress, balance: bigInt)
                NSLog("---- Balance: Fetch token balance for contract \(contract) successfully: \(bigInt.shortString(decimals: 0))")
              case .failure(let error):
                NSLog("---- Balance: Fetch token balance failed with error: \(error.description). ----")
              }
              group.leave()
            }
          })
        }
      }
    }
    // notify when all load balances are done
    group.notify(queue: .main) {
      self.isFetchingOtherTokensBalance = false
      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
    }
  }
}
