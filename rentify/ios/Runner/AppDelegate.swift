import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key - Replace with your actual Google Maps API key from Google Cloud Console
    // Make sure Maps SDK for iOS is enabled in your Google Cloud project
    GMSServices.provideAPIKey("AIzaSyBA9FStEhclV3p4lIWZ-17pJep-DRd01eM")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
