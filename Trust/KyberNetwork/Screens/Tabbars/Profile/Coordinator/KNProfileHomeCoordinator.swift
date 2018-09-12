// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Branch

class KNProfileHomeCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession

  fileprivate(set) var accessTokenExpireTimer: Timer?

  fileprivate(set) var webViewSignInVC: KGOInAppSignInViewController?

  lazy var rootViewController: KNProfileHomeViewController = {
    let viewModel = KNProfileHomeViewModel()
    let controller = KNProfileHomeViewController(viewModel: viewModel)
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

  deinit { self.stop() }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
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
    // Remove notification observer
    self.accessTokenExpireTimer?.invalidate()
    self.accessTokenExpireTimer = nil

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

  // MARK: Update from app coordinator
  func updateSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateWalletObjects() {
  }
}

// MARK: Callbacks, networking
extension KNProfileHomeCoordinator {
  fileprivate func handleUserSignOut() {
    IEOUserStorage.shared.signedOut()
    Branch.getInstance().logout()
    self.rootViewController.coordinatorDidSignOut()
  }

  fileprivate func openSignInView() {
    if let user = IEOUserStorage.shared.user {
      // User already signed in
      self.navigationController.showSuccessTopBannerMessage(with: "", message: "Welcome back, \(user.name)")
      return
    }
    let clientID = KNEnvironment.default == .ropsten ? KNSecret.debugAppID : KNSecret.appID
    let redirectLink = KNEnvironment.default == .ropsten ? KNSecret.debugRedirectURL : KNSecret.redirectURL
    if let url = URL(string: KNAppTracker.getKyberProfileBaseString() + "/oauth/authorize?client_id=\(clientID)&redirect_uri=\(redirectLink)&response_type=code&state=\(KNSecret.state)") {
      // Clear old session
      URLCache.shared.removeAllCachedResponses()
      URLCache.shared.diskCapacity = 0
      URLCache.shared.memoryCapacity = 0

      let storage = HTTPCookieStorage.shared
      storage.cookies?.forEach({ storage.deleteCookie($0) })
      self.webViewSignInVC = KGOInAppSignInViewController(
        with: url,
        isSignIn: true
      )
      self.navigationController.pushViewController(self.webViewSignInVC!, animated: true)
    }
  }

  fileprivate func openSignUpView() {
    if let url = URL(string: KNAppTracker.getKyberProfileBaseString() + "/users/sign_up?normal=true") {
      // Clear old session
      URLCache.shared.removeAllCachedResponses()
      URLCache.shared.diskCapacity = 0
      URLCache.shared.memoryCapacity = 0

      let storage = HTTPCookieStorage.shared
      storage.cookies?.forEach({ storage.deleteCookie($0) })
      self.webViewSignInVC = KGOInAppSignInViewController(
        with: url,
        isSignIn: false
      )
      self.navigationController.pushViewController(self.webViewSignInVC!, animated: true)
    }
  }

  @objc func appCoordinatorDidReceiveCallback(_ sender: Notification) {
    if IEOUserStorage.shared.user != nil { return } // return if user exists
    guard let params = sender.object as? JSONDictionary else { return }
    guard let code = params["code"] as? String, let state = params["state"] as? String, state.contains(KNSecret.state) else { return }
    if self.webViewSignInVC != nil {
      self.navigationController.popViewController(animated: true) {
        self.webViewSignInVC = nil
      }
    }
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
            self?.navigationController.showSuccessTopBannerMessage(with: "", message: "Welcome back, \(user.name)")
            self?.rootViewController.coordinatorUserDidSignInSuccessfully()
          // Already have user
          case .failure(let error):
            self?.navigationController.displayError(error: error)
          }
        }
      })
    }
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
                  expireTime: Date().addingTimeInterval(expireTime).timeIntervalSince1970
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
}

extension KNProfileHomeCoordinator: KNProfileHomeViewControllerDelegate {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNProfileHomeViewEvent) {
    switch event {
    case .signIn:
      self.openSignInView()
    case .signUp:
      self.openSignUpView()
    case .logOut:
      self.handleUserSignOut()
    case .openVerification:
      //TODO:
      print("Open verification")
    case .addWallet:
      //TODO:
      print("Add wallet")
    }
  }
}
