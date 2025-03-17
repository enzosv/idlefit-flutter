import Flutter
import UIKit
import UserNotifications
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, error in
      print("Notification permission granted: \(granted)")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    HealthStatisticsPlugin.register(with: self.registrar(forPlugin: "HealthStatisticsPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
