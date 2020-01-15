// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Branch
import Moya
import Fabric
import Crashlytics
import UserNotificationsUI
import UserNotifications
import OneSignal
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import Firebase
import AppsFlyerLib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, AppsFlyerTrackerDelegate {
  var window: UIWindow?
  var coordinator: KNAppCoordinator!

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in
      DispatchQueue.main.async {
        application.registerForRemoteNotifications()
        application.applicationIconBadgeNumber = 0
      }
    }
    UNUserNotificationCenter.current().delegate = self
    window = UIWindow(frame: UIScreen.main.bounds)
    do {
      let keystore = try EtherKeystore()
      coordinator = KNAppCoordinator(window: window!, keystore: keystore)
      coordinator.start()
      coordinator.appDidFinishLaunch()
    } catch {
      print("EtherKeystore init issue.")
    }
    if !KNEnvironment.default.isMainnet {
      Branch.setUseTestBranchKey(true)
      Branch.getInstance().setDebug()
    }
    Branch.getInstance().initSession(launchOptions: launchOptions) { (_, _) in }
    KNReachability.shared.startNetworkReachabilityObserver()
    Fabric.with([Crashlytics.self])
    OneSignal.setRequiresUserPrivacyConsent(false)
    let notficationReceiveBlock: OSHandleNotificationReceivedBlock = { notification in
      // This block gets called when notification received
      self.coordinator.appDidReceiverOneSignalPushNotification(notification: notification)
    }
    let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
      // This block gets called when the user reacts to a notification received
      self.coordinator.appDidReceiverOneSignalPushNotification(result: result)
    }
    let oneSignalInitSettings = [
      kOSSettingsKeyAutoPrompt: false,
      kOSSettingsKeyInAppLaunchURL: true,
    ]
    OneSignal.initWithLaunchOptions(
      launchOptions,
      appId: KNEnvironment.default.oneSignAppID,
      handleNotificationReceived: notficationReceiveBlock,
      handleNotificationAction: notificationOpenedBlock,
      settings: oneSignalInitSettings
    )
    OneSignal.inFocusDisplayType = .notification
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    FirebaseApp.configure()

    AppsFlyerTracker.shared().appsFlyerDevKey = KNSecret.appsflyerKey
    AppsFlyerTracker.shared().appleAppID = "id1453691309"

    AppsFlyerTracker.shared().delegate = self

    /* Set isDebug to true to see AppsFlyer debug logs */
    AppsFlyerTracker.shared().isDebug = isDebug
    return true
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
    KNAppTracker.updatePushNotificationToken(token)
    if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.updateUserSignedInPushTokenWithRetry() }
  }

  func applicationWillResignActive(_ application: UIApplication) {
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    coordinator.appDidBecomeActive()
    KNReachability.shared.startNetworkReachabilityObserver()
    AppsFlyerTracker.shared().trackAppLaunch()
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    coordinator.appDidEnterBackground()
    KNReachability.shared.stopNetworkReachabilityObserver()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    self.coordinator.appWillEnterForeground()
  }

  func applicationWillTerminate(_ application: UIApplication) {
    self.coordinator.appWillTerminate()
  }

  func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplicationExtensionPointIdentifier) -> Bool {
    if extensionPointIdentifier == UIApplicationExtensionPointIdentifier.keyboard {
      return false
    }
    return true
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Branch.getInstance().handlePushNotification(userInfo)
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
    Branch.getInstance().application(app, open: url, options: options)
    TWTRTwitter.sharedInstance().application(app, open: url, options: options)
    ApplicationDelegate.shared.application(app, open: url, options: options)
    AppsFlyerTracker.shared().handleOpen(url, options: options)
    return true
  }

  // Respond to URI scheme links
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    Branch.getInstance().application(
      application,
      open: url,
      sourceApplication: sourceApplication,
      annotation: annotation
    )
    GIDSignIn.sharedInstance()?.handle(url, sourceApplication: sourceApplication, annotation: annotation)
    AppsFlyerTracker.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
    return true
  }

  // Respond to Universal Links
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    AppsFlyerTracker.shared().continue(userActivity, restorationHandler: nil)
    Branch.getInstance().continue(userActivity)
    return true
  }

  func onConversionDataReceived(_ installData: [AnyHashable: Any]!) {
    guard let first_launch_flag = installData["is_first_launch"] as? Int, first_launch_flag == 1 else {
      return
    }

    guard let status = installData["af_status"] as? String else {
      return
    }

    if first_launch_flag == 1 {
      if status.lowercased() == "non-organic" {
        if let media_source = installData["media_source"] as? String, let campaign = installData["campaign"] as? String {
          KNCrashlyticsUtil.logCustomEvent(
            withName: "non-organic-install",
            customAttributes: ["source": "\(media_source)-\(campaign)"])
        }
      } else {
        KNCrashlyticsUtil.logCustomEvent(
        withName: "organic-install",
        customAttributes: nil)
      }
    }
  }

  func onConversionDataRequestFailure(_ error: Error!) {
    KNCrashlyticsUtil.logCustomEvent(
      withName: "conversion_data_failure",
      customAttributes: nil
    )
  }

  func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]!) {
  }

  func onAppOpenAttributionFailure(_ error: Error!) {
    KNCrashlyticsUtil.logCustomEvent(
      withName: "app_open_attribution_failure",
      customAttributes: nil
    )
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    guard let txHash = response.notification.request.content.userInfo["transaction_hash"] as? String else {
      completionHandler()
      return
    }
    self.coordinator.appDidReceiveLocalNotification(transactionHash: txHash)
    completionHandler()
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound, .badge])
  }
}
