//
//  Generated file. Do not edit.
//
//  Swift registrant avoids ObjC/Swift module conflicts with file_picker under
//  static framework linkage. Regenerate when iOS plugins change (flutter pub get).
//

import Flutter
import Foundation

import background_downloader
import file_picker
import flutter_gemma
import flutter_secure_storage_darwin
import flutter_tts
import integration_test
import large_file_handler
import objectbox_flutter_libs
import permission_handler_apple
import share_plus
import shared_preferences_foundation
import speech_to_text

@objc(GeneratedPluginRegistrant)
public class GeneratedPluginRegistrant: NSObject {
  @objc public static func register(with registry: FlutterPluginRegistry) {
    BackgroundDownloaderPlugin.register(
      with: registry.registrar(forPlugin: "BackgroundDownloaderPlugin")!)
    FilePickerPlugin.register(
      with: registry.registrar(forPlugin: "FilePickerPlugin")!)
    FlutterGemmaPlugin.register(
      with: registry.registrar(forPlugin: "FlutterGemmaPlugin")!)
    FlutterSecureStorageDarwinPlugin.register(
      with: registry.registrar(forPlugin: "FlutterSecureStorageDarwinPlugin")!)
    FlutterTtsPlugin.register(
      with: registry.registrar(forPlugin: "FlutterTtsPlugin")!)
    IntegrationTestPlugin.register(
      with: registry.registrar(forPlugin: "IntegrationTestPlugin")!)
    LargeFileHandlerPlugin.register(
      with: registry.registrar(forPlugin: "LargeFileHandlerPlugin")!)
    ObjectboxFlutterLibsPlugin.register(
      with: registry.registrar(forPlugin: "ObjectboxFlutterLibsPlugin")!)
    PermissionHandlerPlugin.register(
      with: registry.registrar(forPlugin: "PermissionHandlerPlugin")!)
    FPPSharePlusPlugin.register(
      with: registry.registrar(forPlugin: "FPPSharePlusPlugin")!)
    SharedPreferencesPlugin.register(
      with: registry.registrar(forPlugin: "SharedPreferencesPlugin")!)
    SpeechToTextPlugin.register(
      with: registry.registrar(forPlugin: "SpeechToTextPlugin")!)
  }
}
