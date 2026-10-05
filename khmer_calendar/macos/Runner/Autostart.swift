import Foundation
import ServiceManagement

/// Login-item registration.
/// macOS 13+: SMAppService.mainApp (Settings > General > Login Items).
/// macOS 12: System Events login item via AppleScript.
enum KhmerAutostart {
  static func enable() -> Bool {
    if #available(macOS 13.0, *) {
      do {
        try SMAppService.mainApp.register()
      } catch {
        if SMAppService.mainApp.status == .requiresApproval {
          SMAppService.openSystemSettingsLoginItems()
        }
        return SMAppService.mainApp.status == .enabled
      }
      if SMAppService.mainApp.status == .requiresApproval {
        SMAppService.openSystemSettingsLoginItems()
      }
      return SMAppService.mainApp.status == .enabled
    }
    return setLoginItemLegacy(enabled: true)
  }

  static func disable() -> Bool {
    if #available(macOS 13.0, *) {
      do {
        try SMAppService.mainApp.unregister()
      } catch {
        return SMAppService.mainApp.status != .enabled
      }
      return SMAppService.mainApp.status != .enabled
    }
    return setLoginItemLegacy(enabled: false)
  }

  static func isEnabled() -> Bool {
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return loginItemLegacyEnabled()
  }

  private static func appPath() -> String {
    Bundle.main.bundlePath
  }

  private static func quote(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
  }

  private static func runAppleScript(_ source: String) -> NSAppleEventDescriptor? {
    var error: NSDictionary?
    let script = NSAppleScript(source: source)
    let out = script?.executeAndReturnError(&error)
    if error != nil { return nil }
    return out
  }

  private static func setLoginItemLegacy(enabled: Bool) -> Bool {
    let path = quote(appPath())
    let source: String
    if enabled {
      source = """
      tell application "System Events"
        if (count of (every login item whose path is "\(path)")) = 0 then
          make login item at end with properties {path:"\(path)", hidden:false}
        end if
      end tell
      """
    } else {
      source = """
      tell application "System Events"
        delete (every login item whose path is "\(path)")
      end tell
      """
    }
    _ = runAppleScript(source)
    return enabled ? loginItemLegacyEnabled() : !loginItemLegacyEnabled()
  }

  private static func loginItemLegacyEnabled() -> Bool {
    let path = quote(appPath())
    let source = """
    tell application "System Events"
      return (count of (every login item whose path is "\(path)")) > 0
    end tell
    """
    guard let out = runAppleScript(source) else { return false }
    return out.booleanValue
  }
}
