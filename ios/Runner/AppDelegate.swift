import Flutter
import UIKit

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

  private func parseAction(from url: URL) -> String? {
    if url.scheme?.lowercased() != "hisaab" {
      return nil
    }
    let lastComponent = url.pathComponents.last?.lowercased()
    switch lastComponent {
    case "add", "plus":
      return "add"
    case "subtract", "minus", "remove":
      return "subtract"
    default:
      return nil
    }
  }
}
