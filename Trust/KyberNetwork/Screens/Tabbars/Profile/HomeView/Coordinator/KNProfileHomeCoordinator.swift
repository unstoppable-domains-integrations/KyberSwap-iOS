// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Branch
import Result

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

  fileprivate var kycCoordinator: KYCCoordinator?

  fileprivate var loadUserInfoTimer: Timer?

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
    if IEOUserStorage.shared.user != nil {
      self.timerLoadUserInfo()
    }
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

    self.loadUserInfoTimer?.invalidate()
    self.loadUserInfoTimer = nil
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

  fileprivate func timerLoadUserInfo() {
    self.loadUserInfoTimer?.invalidate()
    guard let user = IEOUserStorage.shared.user else {
      self.loadUserInfoTimer?.invalidate()
      return
    }
    self.getUserInfo(
      type: user.tokenType,
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
      expireTime: user.expireTime,
      hasUser: true,
      showError: false
    ) { success in
        if success {
          self.rootViewController.coordinatorUserDidSignInSuccessfully()
        }
    }

    self.loadUserInfoTimer?.invalidate()
    self.loadUserInfoTimer = Timer.scheduledTimer(
      withTimeInterval: KNEnvironment.default == .ropsten ? 10.0 : 60.0,
      repeats: true,
      block: { [weak self] _ in
        guard let user = IEOUserStorage.shared.user else {
          self?.loadUserInfoTimer?.invalidate()
          return
        }
        self?.getUserInfo(
          type: user.tokenType,
          accessToken: user.accessToken,
          refreshToken: user.refreshToken,
          expireTime: user.expireTime,
          hasUser: true,
          showError: false
        ) { success in
            if success {
              self?.rootViewController.coordinatorUserDidSignInSuccessfully()
            }
        }
    })
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
    self.loadUserInfoTimer?.invalidate()
    IEOUserStorage.shared.signedOut()
    Branch.getInstance().logout()
    self.rootViewController.coordinatorDidSignOut()
  }

  fileprivate func openSignInView() {
    if let user = IEOUserStorage.shared.user {
      // User already signed in
      let text = NSLocalizedString("welcome.back.user", comment: "")
      let message = String(format: text, user.name)
      self.navigationController.showSuccessTopBannerMessage(with: "", message: message)
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
    self.navigationController.displayLoading(text: "\(NSLocalizedString("initializing.session", value: "Initializing Session", comment: ""))...", animated: true)
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
                    with: NSLocalizedString("error", comment: ""),
                    message: NSLocalizedString("can.not.get.access.token", comment: "")
                  )
                  return
              }
              self?.getUserInfo(
                type: tokenType,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expireTime:
                Date().addingTimeInterval(expireTime).timeIntervalSince1970,
                hasUser: false,
                showError: true,
                completion: { success in
                  if success {
                    let name = IEOUserStorage.shared.user?.name ?? ""
                    let text = NSLocalizedString("welcome.back.user", comment: "")
                    let message = String(format: text, name)
                    self?.navigationController.showSuccessTopBannerMessage(with: "", message: message)
                  }
              }
              )
            } catch {
              self?.navigationController.hideLoading()
              self?.navigationController.showWarningTopBannerMessage(
                with: NSLocalizedString("error", comment: ""),
                message: NSLocalizedString("can.not.get.access.token", comment: "")
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

  fileprivate func getUserInfo(type: String, accessToken: String, refreshToken: String, expireTime: Double, hasUser: Bool, showError: Bool = false, completion: @escaping (Bool) -> Void) {
    // got access token, user access token  to retrieve user information
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KyberGOService>()
      let userInfoRequest = KyberGOService.getUserInfo(accessToken: accessToken)
      provider.request(userInfoRequest, completion: { [weak self] userInfoResult in
        DispatchQueue.main.async {
          guard let _ = `self` else { return }
          self?.navigationController.hideLoading()
          if hasUser && IEOUserStorage.shared.user == nil {
            self?.loadUserInfoTimer?.invalidate()
            return
          }
          switch userInfoResult {
          case .success(let userInfo):
            guard let userDataJSON = try? userInfo.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let userJSON = userDataJSON else {
              if showError {
                self?.navigationController.showWarningTopBannerMessage(
                  with: NSLocalizedString("error", comment: ""),
                  message: NSLocalizedString("can.not.get.user.info", comment: "")
                )
              }
              completion(false)
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
            if !hasUser { self?.timerLoadUserInfo() }
            self?.rootViewController.coordinatorUserDidSignInSuccessfully()
            completion(true)
          // Already have user
          case .failure(let error):
            if showError {
              self?.navigationController.displayError(error: error)
            }
            completion(false)
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
            title: NSLocalizedString("session.expired", comment: ""),
            body: NSLocalizedString("your.session.has.expired.sign.in.to.continue", comment: "")
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
      self.openVerificationView()
    }
  }

  fileprivate func openVerificationView() {
    guard let user = IEOUserStorage.shared.user else { return }
    self.navigationController.displayLoading(text: "\(NSLocalizedString("checking", value: "Checking", comment: ""))...", animated: true)
    self.getUserInfo(
      type: user.tokenType,
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
      expireTime: user.expireTime,
      hasUser: true,
      showError: true) { [weak self] success in
        guard let `self` = self, let user = IEOUserStorage.shared.user else { return }
        if success {
          self.rootViewController.coordinatorUserDidSignInSuccessfully()
          let status = user.kycStatus.lowercased()
          if status == "approved" || status == "pending" { return }
          if status == "rejected" {
            // need to call remove first
            let alert = UIAlertController(
              title: NSLocalizedString("remove.old.profile", comment: ""),
              message: NSLocalizedString("remove.your.old.profile.to.resubmit", comment: ""),
              preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("remove", comment: ""), style: .destructive, handler: { _ in
              self.sendRemoveProfile(userID: user.userID, accessToken: user.accessToken)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            self.navigationController.present(alert, animated: true, completion: nil)
          } else {
            // draft or none, just open the verification
            self.kycCoordinator = KYCCoordinator(navigationController: self.navigationController, user: user)
            self.kycCoordinator?.delegate = self
            self.kycCoordinator?.start()
          }
        }
    }
  }

  fileprivate func sendRemoveProfile(userID: Int, accessToken: String) {
    let provider = MoyaProvider<ProfileKYCService>()
    let service = ProfileKYCService.removeProfile(accessToken: accessToken, userID: "\(userID)")
    self.navigationController.displayLoading(text: "\(NSLocalizedString("removing", comment: ""))...", animated: true)
    DispatchQueue.global(qos: .background).async {
      provider.request(service) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.navigationController.hideLoading()
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              let json: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success: Bool = json["success"] as? Bool ?? false
              let message: String = {
                if success { return json["message"] as? String ?? "" }
                let reasons: [String] = json["reason"] as? [String] ?? []
                return reasons.isEmpty ? (json["reason"] as? String ?? "Unknown reason") : reasons[0]
              }()
              if !success {
                // Unsuccessful remove profile
                self.navigationController.showErrorTopBannerMessage(
                  with: NSLocalizedString("error", comment: ""),
                  message: message,
                  time: 1.5
                )
              } else {
                // Success
                self.navigationController.showSuccessTopBannerMessage(
                  with: NSLocalizedString("removed", comment: ""),
                  message: NSLocalizedString("your.profile.has.been.removed.can.resubmit.now", comment: ""),
                  time: 2.0
                )
                guard let user = IEOUserStorage.shared.user else { return }
                self.navigationController.displayLoading(text: "\(NSLocalizedString("updating.info", comment: ""))...", animated: true)
                self.getUserInfo(
                  type: user.tokenType,
                  accessToken: user.accessToken,
                  refreshToken: user.refreshToken,
                  expireTime: user.expireTime,
                  hasUser: true,
                  showError: true,
                  completion: { [weak self] success in
                  if success {
                    self?.rootViewController.coordinatorUserDidSignInSuccessfully()
                    // Open verification view again
                    self?.openVerificationView()
                  }
                })
              }
            } catch let error {
              self.navigationController.displayError(error: error)
            }
          case .failure(let error):
            self.navigationController.displayError(error: error)
          }
        }
      }
    }
  }
}

extension KNProfileHomeCoordinator: KYCCoordinatorDelegate {
  func kycCoordinatorDidSubmitData() {
    guard let user = IEOUserStorage.shared.user else { return }
    self.navigationController.displayLoading()
    self.getUserInfo(
      type: user.tokenType,
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
      expireTime: user.expireTime,
      hasUser: true,
      showError: true,
      completion: { success in
        if success {
          self.rootViewController.coordinatorUserDidSignInSuccessfully()
        }
      }
    )
  }
}
