// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya

class KNRecentTradeCoordinator {

  static let shared: KNRecentTradeCoordinator = KNRecentTradeCoordinator()

//  fileprivate var recentTradeFetchTimer: Timer?
//  fileprivate var isLoadingRecentTrade: Bool = false

//  fileprivate var recentTransactions: [KNTransaction] = []

  fileprivate let provider = MoyaProvider<KyberNetworkService>()

  init() { }

  func resume() {
//    recentTradeFetchTimer?.invalidate()
//    fetchRecentTrade(nil)

//    recentTradeFetchTimer = Timer.scheduledTimer(
//      timeInterval: KNLoadingInterval.defaultLoadingInterval,
//      target: self,
//      selector: #selector(self.fetchRecentTrade(_:)),
//      userInfo: nil,
//      repeats: true
//    )
  }

  func pause() {
//    self.isLoadingRecentTrade = false
//    self.recentTradeFetchTimer?.invalidate()
//    self.recentTradeFetchTimer = nil
  }

//  @objc func fetchRecentTrade(_ sender: Timer?) {
//    if isLoadingRecentTrade { return }
//    isLoadingRecentTrade = true
//    KNInternalProvider.shared.getKNRecentTrades { [weak self] result in
//      if case .success(let trans) = result {
//        self?.recentTransactions = trans
//      }
//    }
//  }
}
