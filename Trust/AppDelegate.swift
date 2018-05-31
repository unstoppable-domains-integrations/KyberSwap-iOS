// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Lokalise

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
    var coordinator: KNAppCoordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        do {
            let keystore = try EtherKeystore()
            coordinator = KNAppCoordinator(window: window!, keystore: keystore)
            coordinator.start()
            coordinator.appDidFinishLaunch()
        } catch {
            print("EtherKeystore init issue.")
        }
        KNReachability.shared.startNetworkReachabilityObserver()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        coordinator.appDidBecomeActive()
        KNReachability.shared.startNetworkReachabilityObserver()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        coordinator.appDidEnterBackground()
      KNReachability.shared.stopNetworkReachabilityObserver()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
      self.coordinator.appWillEnterForeground()
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
    }

    // Respond to URI scheme links
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

        // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
        return true
    }

    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return true
    }
}
