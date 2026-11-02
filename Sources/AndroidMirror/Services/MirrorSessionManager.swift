//
//  MirrorSessionManager.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created MirrorSessionManager to orchestrate the lifecycle of active scrcpy
//              mirroring sessions with tailored flags that mirror Apple's iPhone Mirroring experience
//              (screen-off mode, audio forwarding, stay-awake, and custom keyboard modifiers).
//  How: Implemented as a MainActor Observable class with Process monitoring and status broadcasting.
//

import Foundation
import Observation

@Observable
@MainActor
public final class MirrorSessionManager {
    public static let shared = MirrorSessionManager()

    public var isSessionActive: Bool = false
    public var activeDevice: AndroidDevice?
    public var lastError: String?
    public var consoleLogs: [String] = []

    private var activeProcess: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var currentConfig: MirrorConfig?
    private var currentDeviceId: String?

    public init() {}

    public func startMirroring(device: AndroidDevice, config: MirrorConfig) async {
        guard !isSessionActive else {
            stopMirroring()
            return
        }

        let adbService = AdbService.shared
        guard let scrcpyPath = await adbService.findScrcpyPath() else {
            self.lastError = "scrcpy binary not found. Please install scrcpy via Homebrew: brew install scrcpy"
            return
        }

        self.lastError = nil
        self.activeDevice = device
        self.currentConfig = config
        self.currentDeviceId = device.id
        self.consoleLogs.removeAll()

        // Change Description:
        // Author: Nipuna Lakruwan
        // Date: 2026-11-02
        // Previous Code: Only passed --turn-screen-off without --no-power-on or virtual display or touch suppression,
        //                allowing accidental physical touches to register on the device.
        // Modified Code: Added virtual display mode (--new-display), --no-power-on flag, and automatic ADB touch-wake
        //                suppression to prevent physical touch input while the phone screen is completely off.
        // How: Conditionally adds --new-display or --turn-screen-off with --no-power-on and temporarily disables double-tap wake.
        if config.disableTouchWake {
            await adbService.setTouchWakeSuppression(serial: device.id, enabled: true)
        }

        var arguments: [String] = [
            "--serial", device.id,
            "--window-title", "Android Mirror (\(device.displayName))",
            // Map scrcpy modifiers to Left Super (Mac Cmd) and Option so Cmd+C / Cmd+V copy and paste directly
            "--shortcut-mod=lsuper,lalt"
        ]

        if !config.clipboardAutoSync {
            arguments.append("--no-clipboard-autosync")
        }

        if config.legacyPaste {
            arguments.append("--legacy-paste")
        }

        if config.useVirtualDisplay {
            // Android 13/14+ Virtual Display Isolation: creates an independent virtual screen
            // Physical phone screen stays completely dark and locked; physical touches to phone are ignored.
            arguments.append("--new-display")
            if config.noPowerOn {
                arguments.append("--no-power-on")
            }
        } else {
            // iPhone Mirroring emulation: Turn physical phone screen black/off while in use
            if config.turnScreenOff {
                arguments.append("--turn-screen-off")
            }
            if config.noPowerOn {
                arguments.append("--no-power-on")
            }
        }

        if config.stayAwake {
            arguments.append("--stay-awake")
        }

        if config.forwardAudio {
            arguments.append("--audio-codec=opus")
        } else {
            arguments.append("--no-audio")
        }

        if config.alwaysOnTop {
            arguments.append("--always-on-top")
        }

        if config.maxResolution > 0 {
            arguments.append(contentsOf: ["--max-size", String(config.maxResolution)])
        }

        if config.bitRateMbps > 0 {
            arguments.append(contentsOf: ["--video-bit-rate", "\(config.bitRateMbps)M"])
        }

        if config.maxFps > 0 {
            arguments.append(contentsOf: ["--max-fps", String(config.maxFps)])
        }

        if config.powerOffOnClose {
            arguments.append("--power-off-on-close")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: scrcpyPath)
        process.arguments = arguments

        // Ensure adb binary is discoverable in PATH for scrcpy
        var environment = ProcessInfo.processInfo.environment
        if let adbPath = await adbService.findAdbPath() {
            let adbDir = URL(fileURLWithPath: adbPath).deletingLastPathComponent().path
            let currentPath = environment["PATH"] ?? ""
            environment["PATH"] = "\(adbDir):\(currentPath)"
        }
        process.environment = environment

        let stdout = Pipe()
        let stderr = Pipe()
        self.stdoutPipe = stdout
        self.stderrPipe = stderr

        process.standardOutput = stdout
        process.standardError = stderr

        process.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Restore touch wake settings on session exit
                if let devId = self.currentDeviceId, let cfg = self.currentConfig, cfg.disableTouchWake {
                    Task { await AdbService.shared.setTouchWakeSuppression(serial: devId, enabled: false) }
                }
                self.isSessionActive = false
                self.activeDevice = nil
                self.activeProcess = nil
                self.currentDeviceId = nil
                self.appendLog("Session ended with status: \(proc.terminationStatus)")
            }
        }

        do {
            try process.run()
            self.activeProcess = process
            self.isSessionActive = true
            self.appendLog("Mirroring session started for \(device.displayName)...")

            // Monitor output stream in background
            setupStreamReaders(stdout: stdout, stderr: stderr)
        } catch {
            // Restore touch wake if launch fails
            if config.disableTouchWake {
                Task { await AdbService.shared.setTouchWakeSuppression(serial: device.id, enabled: false) }
            }
            self.lastError = "Failed to launch scrcpy process: \(error.localizedDescription)"
            self.isSessionActive = false
            self.activeDevice = nil
            self.currentDeviceId = nil
        }
    }

    public func stopMirroring() {
        // Restore touch wake settings when manually stopped
        if let devId = currentDeviceId, let cfg = currentConfig, cfg.disableTouchWake {
            Task { await AdbService.shared.setTouchWakeSuppression(serial: devId, enabled: false) }
        }

        guard let process = activeProcess, process.isRunning else {
            isSessionActive = false
            activeDevice = nil
            activeProcess = nil
            currentDeviceId = nil
            return
        }

        process.terminate()
        activeProcess = nil
        isSessionActive = false
        activeDevice = nil
        currentDeviceId = nil
        appendLog("Session stopped by user.")
    }

    private func setupStreamReaders(stdout: Pipe, stderr: Pipe) {
        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.appendLog(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }

        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    self?.appendLog("[scrcpy] " + trimmed)
                    if trimmed.localizedCaseInsensitiveContains("error") {
                        self?.lastError = trimmed
                    }
                }
            }
        }
    }

    private func appendLog(_ message: String) {
        guard !message.isEmpty else { return }
        consoleLogs.append(message)
        if consoleLogs.count > 100 {
            consoleLogs.removeFirst(consoleLogs.count - 100)
        }
    }
}
