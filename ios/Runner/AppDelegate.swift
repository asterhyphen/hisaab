import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pendingAction: String?
  private var widgetChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      widgetChannel = FlutterMethodChannel(
        name: "hisaab/widget",
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel?.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        if call.method == "getInitialAction" {
          result(self.pendingAction)
          self.pendingAction = nil
          return
        }
        if call.method == "updateWidgetBalance" {
          if let args = call.arguments as? [String: Any], let balance = args["balance"] as? Double {
            self.updateWidgetBalance(balance)
            result(nil)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Balance must be a double", details: nil))
          }
          return
        }
        result(FlutterMethodNotImplemented)
      }
    }

    if let url = launchOptions?[.url] as? URL {
      pendingAction = parseAction(from: url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if let action = parseAction(from: url) {
      if widgetChannel == nil {
        pendingAction = action
      } else {
        widgetChannel?.invokeMethod("onWidgetAction", arguments: action)
      }
    }
    return super.application(app, open: url, options: options)
  }

  private func updateWidgetBalance(_ balance: Double) {
    let sharedDefaults = UserDefaults(suiteName: "group.dev.aster.hisaab")
    sharedDefaults?.set(balance, forKey: "totalBalance")
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func updateWidgetBalance(_ balance: Double) {
    let sharedDefaults = UserDefaults(suiteName: "group.dev.aster.hisaab")
    sharedDefaults?.set(balance, forKey: "totalBalance")
    sharedDefaults?.synchronize()
    
    // Reload widget timelines
    WidgetCenter.shared.reloadAllTimelines()
  }
}
