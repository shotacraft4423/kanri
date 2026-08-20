import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyOverlay: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // アプリ切替画面(App Switcher)のサムネイルに機密情報が写らないよう、
  // バックグラウンド遷移時にぼかしを重ねる。iOSはOS仕様上スクリーンショット自体は
  // ブロックできないため、この対策はタスクスイッチャーでの見え方の軽減に留まる。
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    guard let window = self.window else { return }
    let blurEffect = UIBlurEffect(style: .systemMaterial)
    let overlay = UIVisualEffectView(effect: blurEffect)
    overlay.frame = window.bounds
    overlay.tag = 999_001
    window.addSubview(overlay)
    privacyOverlay = overlay
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
