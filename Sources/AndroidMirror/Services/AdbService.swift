//
//  AdbService.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created AdbService to interface with Android Debug Bridge (adb) and scrcpy binaries.
//              Handles device discovery, property queries, hardware key event injection,
//              wireless ADB setup, screenshot generation, and file transfers.
//  How: Implemented as an actor conforming to Sendable for thread-safe asynchronous execution.
//

import Foundation

public actor AdbService {
    public static let shared = AdbService()
    
    private var cachedAdbPath: String?
    private var cachedScrcpyPath: String?

    public init() {}

    // MARK: - Binary Path Discovery
    
    public func findAdbPath() -> String? {
        if let path = cachedAdbPath, FileManager.default.isExecutableFile(atPath: path) {
            return path
        }

        let searchCandidates = [
            "/Volumes/DevDrive/Apps/AndroidSDK/platform-tools/adb",
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Android/sdk/platform-tools/adb").path,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".android-sdk/platform-tools/adb").path,
            "/usr/bin/adb"
        ]

        for candidate in searchCandidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                cachedAdbPath = candidate
                return candidate
            }
        }

        // Fallback to checking PATH via which
        if let whichPath = runSystemCommand("/usr/bin/which", arguments: ["adb"])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !whichPath.isEmpty, FileManager.default.isExecutableFile(atPath: whichPath) {
            cachedAdbPath = whichPath
            return whichPath
        }

        return nil
    }

    public func findScrcpyPath() -> String? {
        if let path = cachedScrcpyPath, FileManager.default.isExecutableFile(atPath: path) {
            return path
        }

        let searchCandidates = [
            "/opt/homebrew/bin/scrcpy",
            "/usr/local/bin/scrcpy",
            "/usr/bin/scrcpy"
        ]

        for candidate in searchCandidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                cachedScrcpyPath = candidate
                return candidate
            }
        }

        if let whichPath = runSystemCommand("/usr/bin/which", arguments: ["scrcpy"])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !whichPath.isEmpty, FileManager.default.isExecutableFile(atPath: whichPath) {
            cachedScrcpyPath = whichPath
            return whichPath
        }

        return nil
    }

    // MARK: - Process Execution

    @discardableResult
    public func execute(arguments: [String]) async throws -> String {
        guard let adb = findAdbPath() else {
            throw AdbError.adbNotFound
        }

        return try await runProcess(executable: adb, arguments: arguments)
    }

    private func runProcess(executable: String, arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
                process.waitUntilExit()

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdoutText = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderrText = String(data: stderrData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: stdoutText)
                } else {
                    continuation.resume(throwing: AdbError.commandFailed(
                        code: process.terminationStatus,
                        message: stderrText.isEmpty ? stdoutText : stderrText
                    ))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func runSystemCommand(_ executable: String, arguments: [String]) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    // MARK: - Device Listing & Details

    public func listDevices() async throws -> [AndroidDevice] {
        let output = try await execute(arguments: ["devices", "-l"])
        var devices: [AndroidDevice] = []

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("List of devices") {
                continue
            }

            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2 else { continue }

            let serial = parts[0]
            let rawState = parts[1]

            let state: DeviceState
            switch rawState {
            case "device":
                state = .device
            case "unauthorized":
                state = .unauthorized
            case "offline":
                state = .offline
            default:
                state = .connecting
            }

            var model = "Android Device"
            // Change Description:
            // Author: Nipuna Lakruwan
            // Date: 2026-11-02
            // Previous Code: 'var connType: ConnectionType = ...' triggered variable never mutated warning.
            // Modified Code: Changed 'var connType' to 'let connType'.
            // How: Declared as immutable constant.
            let connType: ConnectionType = serial.contains(":") ? .wifi : .usb

            for part in parts.dropFirst(2) {
                if part.hasPrefix("model:") {
                    model = part.replacingOccurrences(of: "model:", with: "").replacingOccurrences(of: "_", with: " ")
                } else if part.hasPrefix("transport_id:") {
                    // transport indicator
                }
            }

            var device = AndroidDevice(
                id: serial,
                modelName: model,
                state: state,
                connectionType: connType
            )

            if state == .device {
                let details = await getDeviceDetails(serial: serial)
                device.modelName = details.model.isEmpty ? model : details.model
                device.manufacturer = details.manufacturer
                device.androidVersion = details.version
                device.batteryLevel = details.battery
                device.isCharging = details.isCharging
                device.ipAddress = details.ip
            }

            devices.append(device)
        }

        return devices
    }

    public func getDeviceDetails(serial: String) async -> (
        model: String,
        manufacturer: String,
        version: String,
        battery: Int?,
        isCharging: Bool,
        ip: String?
    ) {
        async let modelQuery = queryProp(serial: serial, prop: "ro.product.model")
        async let manufacturerQuery = queryProp(serial: serial, prop: "ro.product.manufacturer")
        async let versionQuery = queryProp(serial: serial, prop: "ro.build.version.release")
        async let batteryQuery = queryBattery(serial: serial)
        async let ipQuery = queryDeviceIP(serial: serial)

        let model = await modelQuery
        let manufacturer = await manufacturerQuery
        let version = await versionQuery
        let batteryInfo = await batteryQuery
        let ip = await ipQuery

        return (
            model: model.replacingOccurrences(of: "_", with: " "),
            manufacturer: manufacturer.capitalized,
            version: version,
            battery: batteryInfo.level,
            isCharging: batteryInfo.charging,
            ip: ip
        )
    }

    private func queryProp(serial: String, prop: String) async -> String {
        do {
            let output = try await execute(arguments: ["-s", serial, "shell", "getprop", prop])
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return ""
        }
    }

    private func queryBattery(serial: String) async -> (level: Int?, charging: Bool) {
        do {
            let output = try await execute(arguments: ["-s", serial, "shell", "dumpsys", "battery"])
            var level: Int? = nil
            var isCharging = false

            for line in output.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("level:") {
                    let val = trimmed.replacingOccurrences(of: "level:", with: "").trimmingCharacters(in: .whitespaces)
                    level = Int(val)
                } else if trimmed.hasPrefix("status:") {
                    // status 2 is BATTERY_STATUS_CHARGING
                    let val = trimmed.replacingOccurrences(of: "status:", with: "").trimmingCharacters(in: .whitespaces)
                    if val == "2" {
                        isCharging = true
                    }
                }
            }
            return (level, isCharging)
        } catch {
            return (nil, false)
        }
    }

    // Change Description:
    // Author: Nipuna Lakruwan
    // Date: 2026-11-02
    // Previous Code: queryDeviceIP only queried wlan0, causing failures on Samsung devices and Mobile Hotspots (ap_br_swlan0).
    // Modified Code: Rewrote queryDeviceIP to inspect all non-loopback, non-cellular interfaces
    //                (supporting wlan0, ap_br_swlan0, swlan0, softap, rndis), prioritizing hotspot/Wi-Fi IPs,
    //                and falling back to the Mac default Wi-Fi gateway IP when connected to a phone hotspot.
    // How: Parses all inet lines from 'ip -f inet addr show' and cross-references with interface names.
    public func queryDeviceIP(serial: String) async -> String? {
        do {
            let output = try await execute(arguments: ["-s", serial, "shell", "ip", "-f", "inet", "addr", "show"])
            var hotspotIP: String?
            var wifiIP: String?
            var otherIP: String?
            var currentIface = ""

            for line in output.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.range(of: #"^\d+:\s+([a-zA-Z0-9_\@\-]+):"#, options: .regularExpression) != nil {
                    let parts = trimmed.components(separatedBy: ":")
                    if parts.count >= 2 {
                        currentIface = parts[1].trimmingCharacters(in: .whitespaces)
                        if let atIdx = currentIface.firstIndex(of: "@") {
                            currentIface = String(currentIface[..<atIdx])
                        }
                    }
                } else if trimmed.hasPrefix("inet ") {
                    let tokens = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard tokens.count >= 2 else { continue }
                    let ipWithCidr = tokens[1]
                    let ip = ipWithCidr.components(separatedBy: "/")[0]

                    // Exclude loopback and cellular data interfaces (rmnet, ccmni, pdp, dummy, tun)
                    if ip == "127.0.0.1" || currentIface == "lo" ||
                       currentIface.hasPrefix("rmnet") ||
                       currentIface.hasPrefix("ccmni") ||
                       currentIface.hasPrefix("pdp") ||
                       currentIface.hasPrefix("dummy") ||
                       currentIface.hasPrefix("tun") {
                        continue
                    }

                    // Categorize interface
                    if currentIface.contains("ap") || currentIface.contains("swlan") || currentIface.contains("softap") {
                        hotspotIP = ip
                    } else if currentIface.hasPrefix("wlan") {
                        wifiIP = ip
                    } else {
                        otherIP = ip
                    }
                }
            }

            // Return hotspot IP first (if active), then Wi-Fi, then other local network IP
            if let detected = hotspotIP ?? wifiIP ?? otherIP {
                return detected
            }
        } catch {
            // Ignore error and try gateway fallback
        }

        // Fallback: If Mac is connected to phone hotspot, Mac default gateway is the phone
        if let gateway = detectHotspotGatewayIP() {
            return gateway
        }

        return nil
    }

    // MARK: - Hardware Navigation & Control Injection

    public func sendKeyEvent(serial: String, keyCode: Int) async throws {
        try await execute(arguments: ["-s", serial, "shell", "input", "keyevent", String(keyCode)])
    }

    // Replicates macOS Cmd+1 for Home
    public func sendHomeKey(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 3) // KEYCODE_HOME
    }

    // Replicates macOS Cmd+2 for App Switcher
    public func sendAppSwitchKey(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 187) // KEYCODE_APP_SWITCH
    }

    // Replicates Back action (Escape or Cmd+[)
    public func sendBackKey(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 4) // KEYCODE_BACK
    }

    // Replicates Lock / Power toggle
    public func sendPowerKey(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 26) // KEYCODE_POWER
    }

    public func sendVolumeUp(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 24) // KEYCODE_VOLUME_UP
    }

    public func sendVolumeDown(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 25) // KEYCODE_VOLUME_DOWN
    }

    public func expandNotifications(serial: String) async throws {
        try await execute(arguments: ["-s", serial, "shell", "cmd", "statusbar", "expand-notifications"])
    }

    public func expandSettings(serial: String) async throws {
        try await execute(arguments: ["-s", serial, "shell", "cmd", "statusbar", "expand-settings"])
    }

    public func collapsePanels(serial: String) async throws {
        try await execute(arguments: ["-s", serial, "shell", "cmd", "statusbar", "collapse"])
    }

    // MARK: - Clipboard Synchronization
    //
    // Change Description:
    // Author: Nipuna Lakruwan
    // Date: 2026-11-02
    // Previous Code: Did not have dedicated ADB copy and paste keyevent/text injection helpers.
    // Modified Code: Added sendCopyCommand, sendPasteCommand, and injectTextToDevice for cross-device copy-paste.
    // How: Implemented KEYCODE_COPY (278), KEYCODE_PASTE (279), and 'input text' shell commands with character escaping.

    public func sendCopyCommand(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 278) // KEYCODE_COPY
    }

    public func sendPasteCommand(serial: String) async throws {
        try await sendKeyEvent(serial: serial, keyCode: 279) // KEYCODE_PASTE
    }

    public func injectTextToDevice(serial: String, text: String) async throws {
        guard !text.isEmpty else { return }

        // Sanitize and escape string for Android 'input text'
        // Spaces in Android 'input text' must be represented as %s
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: " ", with: "%s")
            .replacingOccurrences(of: "&", with: "\\&")
            .replacingOccurrences(of: "<", with: "\\<")
            .replacingOccurrences(of: ">", with: "\\>")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "|", with: "\\|")

        try await execute(arguments: ["-s", serial, "shell", "input", "text", escaped])
    }

    // MARK: - Screenshot Capture

    public func takeScreenshot(serial: String, destinationPath: String) async throws {
        let tempRemotePath = "/sdcard/screenshot_android_mirror.png"
        try await execute(arguments: ["-s", serial, "shell", "screencap", "-p", tempRemotePath])
        try await execute(arguments: ["-s", serial, "pull", tempRemotePath, destinationPath])
        // Change Description:
        // Author: Nipuna Lakruwan
        // Date: 2026-11-02
        // Previous Code: 'try? await execute(...)' triggered unused result warning.
        // Modified Code: Explicitly ignored the return value with '_ = try? await execute(...)'.
        // How: Prefixed with discard assignment.
        _ = try? await execute(arguments: ["-s", serial, "shell", "rm", "-f", tempRemotePath])
    }

    // MARK: - Wireless ADB Pairing

    // MARK: - Wireless ADB & Hotspot Auto-Discovery
    //
    // Change Description:
    // Author: Nipuna Lakruwan
    // Date: 2026-11-02
    // Previous Code: Only basic connectWireless and enableTcpIp were implemented.
    // Modified Code: Added automatic hotspot gateway detection, multi-interface IP parsing
    //                (wlan0, ap0, swlan0), seamless USB-to-wireless handoff preparation,
    //                and automated connection attempts to trusted devices.
    // How: Implemented system route parsing, Android IP extraction, and sequenced connect calls.

    public func detectHotspotGatewayIP() -> String? {
        guard let output = runSystemCommand("/sbin/route", arguments: ["-n", "get", "default"]) else {
            return nil
        }

        var isWifi = false
        var gatewayIp: String?

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("interface:") {
                let iface = trimmed.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces)
                // en0 is standard macOS Wi-Fi interface
                if iface.hasPrefix("en") {
                    isWifi = true
                }
            } else if trimmed.hasPrefix("gateway:") {
                gatewayIp = trimmed.replacingOccurrences(of: "gateway:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        if isWifi, let ip = gatewayIp, !ip.isEmpty {
            return ip
        }
        return nil
    }

    // Change Description:
    // Author: Nipuna Lakruwan
    // Date: 2026-11-02
    // Previous Code: getDeviceNetworkIPs checked fixed interface names (ap0, swlan0), failing on ap_br_swlan0.
    // Modified Code: Broadened interface detection to recognize any hotspot interface containing 'ap' or 'swlan',
    //                and any Wi-Fi interface starting with 'wlan'. Added fallback to Mac default gateway for hotspot.
    // How: Updated string condition matching and gateway fallback.
    public func getDeviceNetworkIPs(serial: String) async -> (wifiIP: String?, hotspotIP: String?) {
        do {
            let output = try await execute(arguments: ["-s", serial, "shell", "ip", "-f", "inet", "addr", "show"])
            var wifiIP: String?
            var hotspotIP: String?
            var otherIP: String?
            var currentInterface = ""

            for line in output.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.range(of: #"^\d+:\s+([a-zA-Z0-9_\@\-]+):"#, options: .regularExpression) != nil {
                    let parts = trimmed.components(separatedBy: ":")
                    if parts.count >= 2 {
                        currentInterface = parts[1].trimmingCharacters(in: .whitespaces)
                        if let atIdx = currentInterface.firstIndex(of: "@") {
                            currentInterface = String(currentInterface[..<atIdx])
                        }
                    }
                } else if trimmed.hasPrefix("inet ") {
                    let tokens = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if tokens.count >= 2 {
                        let ipAndCidr = tokens[1]
                        let ipOnly = ipAndCidr.components(separatedBy: "/")[0]

                        if ipOnly == "127.0.0.1" || currentInterface == "lo" ||
                           currentInterface.hasPrefix("rmnet") ||
                           currentInterface.hasPrefix("ccmni") ||
                           currentInterface.hasPrefix("pdp") {
                            continue
                        }

                        if currentInterface.contains("ap") || currentInterface.contains("swlan") || currentInterface.contains("softap") {
                            hotspotIP = ipOnly
                        } else if currentInterface.hasPrefix("wlan") {
                            wifiIP = ipOnly
                        } else {
                            otherIP = ipOnly
                        }
                    }
                }
            }

            if hotspotIP == nil, let gateway = detectHotspotGatewayIP() {
                hotspotIP = gateway
            }

            return (wifiIP ?? otherIP, hotspotIP)
        } catch {
            return (nil, nil)
        }
    }

    public func prepareWirelessHandoff(serial: String, port: Int = 5555) async -> (wifiIP: String?, hotspotIP: String?) {
        // 1. Arm ADB TCP/IP on the device
        _ = try? await enableTcpIp(serial: serial, port: port)

        // 2. Discover device Wi-Fi and Hotspot IPs
        let ips = await getDeviceNetworkIPs(serial: serial)

        // 3. Pre-connect over Wi-Fi so wireless session is ready before unplugging cable
        if let wifi = ips.wifiIP {
            _ = try? await connectWireless(ipAddress: wifi, port: port)
        }
        if let hotspot = ips.hotspotIP {
            _ = try? await connectWireless(ipAddress: hotspot, port: port)
        }

        return ips
    }

    public func autoConnectToTrusted(trusted: TrustedDevice, port: Int = 5555) async -> Bool {
        // Option A: If Mac is connected to phone's Wi-Fi hotspot, phone is the network gateway
        if let gateway = detectHotspotGatewayIP() {
            if let ok = try? await connectWireless(ipAddress: gateway, port: port), ok {
                return true
            }
        }

        // Option B: Try last known Wi-Fi IP
        if let lastIP = trusted.lastKnownIP {
            if let ok = try? await connectWireless(ipAddress: lastIP, port: port), ok {
                return true
            }
        }

        // Option C: Try last known Hotspot IP
        if let hotspotIP = trusted.lastKnownHotspotIP {
            if let ok = try? await connectWireless(ipAddress: hotspotIP, port: port), ok {
                return true
            }
        }

        return false
    }

    public func enableTcpIp(serial: String, port: Int = 5555) async throws {
        try await execute(arguments: ["-s", serial, "tcpip", String(port)])
    }

    public func connectWireless(ipAddress: String, port: Int = 5555) async throws -> Bool {
        let endpoint = "\(ipAddress):\(port)"
        let output = try await execute(arguments: ["connect", endpoint])
        return output.contains("connected to")
    }

    public func disconnectWireless(ipAddress: String, port: Int = 5555) async throws {
        let endpoint = "\(ipAddress):\(port)"
        _ = try? await execute(arguments: ["disconnect", endpoint])
    }

    // MARK: - File & APK Transfer

    public func pushFile(serial: String, localPath: String, remotePath: String = "/sdcard/Download/") async throws {
        try await execute(arguments: ["-s", serial, "push", localPath, remotePath])
    }

    public func installApk(serial: String, apkPath: String) async throws {
        try await execute(arguments: ["-s", serial, "install", "-r", apkPath])
    }

    // MARK: - Display & Touch Suppression
    // Change Description:
    // Author: Nipuna Lakruwan
    // Date: 2026-11-02
    // Previous Code: Lacked methods to suppress physical touch wake events during mirroring.
    // Added Code: Added setTouchWakeSuppression to disable double_tap_to_wake and wake_gesture_enabled on the device,
    //             preventing accidental physical taps from waking the screen or triggering phantom inputs while screen is off.
    // How: Invokes adb shell settings put secure for double_tap_to_wake and wake_gesture_enabled.
    public func setTouchWakeSuppression(serial: String, enabled: Bool) async {
        let value = enabled ? "0" : "1"
        _ = try? await execute(arguments: ["-s", serial, "shell", "settings", "put", "secure", "double_tap_to_wake", value])
        _ = try? await execute(arguments: ["-s", serial, "shell", "settings", "put", "secure", "wake_gesture_enabled", value])
    }
}

public enum AdbError: LocalizedError {
    case adbNotFound
    case scrcpyNotFound
    case commandFailed(code: Int32, message: String)

    public var errorDescription: String? {
        switch self {
        case .adbNotFound:
            return "Android Debug Bridge (adb) was not found on your system. Please verify Android SDK or Homebrew installation."
        case .scrcpyNotFound:
            return "scrcpy binary was not found. Please verify scrcpy installation via Homebrew (brew install scrcpy)."
        case .commandFailed(let code, let message):
            return "ADB command failed with exit code \(code): \(message)"
        }
    }
}
