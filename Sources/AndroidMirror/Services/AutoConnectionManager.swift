//
//  AutoConnectionManager.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: AutoConnectionManager checked for hardcoded 'Samsung' or 'S23' strings.
//  Modified Code: Completely removed hardcoded brand checks. ANY connected Android device
//                 is now dynamically recognized, has its real model and IP saved, and is retained
//                 in TrustedDeviceStore permanently until the app or pairing is removed.
//  How: Replaced specific brand filters with universal active device discovery and storage.
//

import Foundation
import Observation

public enum ConnectionMode: String, Sendable {
    case disconnected = "Disconnected"
    case searching = "Searching..."
    case connectedUsb = "Connected via USB"
    case connectedWifi = "Connected via Wi-Fi"
    case connectedHotspot = "Connected via Hotspot"
}

@Observable
@MainActor
public final class AutoConnectionManager {
    public static let shared = AutoConnectionManager()

    public var connectionMode: ConnectionMode = .disconnected
    public var statusDescription: String = "Waiting for connection..."
    public var trustedDevice: TrustedDevice?
    public var isAutoConnecting: Bool = false

    private var pollerTask: Task<Void, Never>?
    private var isPolling: Bool = false

    public init() {
        self.trustedDevice = TrustedDeviceStore.getPrimaryDevice()
    }

    public func startBackgroundPolling(config: MirrorConfig, onDeviceAvailable: @escaping (AndroidDevice) -> Void) {
        guard pollerTask == nil else { return }

        pollerTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.performConnectionCycle(config: config, onDeviceAvailable: onDeviceAvailable)
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds interval
            }
        }
    }

    public func stopBackgroundPolling() {
        pollerTask?.cancel()
        pollerTask = nil
    }

    public func setTrustedDevice(_ device: TrustedDevice) {
        self.trustedDevice = device
        TrustedDeviceStore.saveOrUpdateDevice(device)
    }

    private func performConnectionCycle(
        config: MirrorConfig,
        onDeviceAvailable: @escaping (AndroidDevice) -> Void
    ) async {
        guard !MirrorSessionManager.shared.isSessionActive else {
            return
        }

        let adbService = AdbService.shared

        do {
            let activeDevices = try await adbService.listDevices()

            // 1. Check if an authorized device is currently connected
            if let active = activeDevices.first(where: { $0.state == .device }) {
                // If it's a USB device, automatically set up wireless handoff
                if !active.isWireless {
                    self.connectionMode = .connectedUsb
                    self.statusDescription = "Connected via USB: \(active.displayName)"

                    // Dynamically save or update any connected phone as the remembered device
                    var trusted = trustedDevice ?? TrustedDevice(
                        id: active.id,
                        name: active.displayName,
                        model: active.modelName,
                        manufacturer: active.manufacturer
                    )
                    trusted.id = active.id
                    trusted.name = active.displayName
                    trusted.model = active.modelName
                    trusted.manufacturer = active.manufacturer
                    trusted.lastConnectedAt = Date()

                    // Prepare wireless handoff in background
                    let ips = await adbService.prepareWirelessHandoff(serial: active.id)
                    if let wifi = ips.wifiIP {
                        trusted.lastKnownIP = wifi
                    }
                    if let hotspot = ips.hotspotIP {
                        trusted.lastKnownHotspotIP = hotspot
                    }

                    self.trustedDevice = trusted
                    TrustedDeviceStore.saveOrUpdateDevice(trusted)

                    onDeviceAvailable(active)
                    return
                } else {
                    // Connected via Wi-Fi or Hotspot
                    let isHotspot = await isHotspotEndpoint(active.id)
                    self.connectionMode = isHotspot ? .connectedHotspot : .connectedWifi
                    self.statusDescription = isHotspot
                        ? "Connected via Mobile Hotspot (\(active.displayName))"
                        : "Connected via Wi-Fi (\(active.displayName))"

                    onDeviceAvailable(active)
                    return
                }
            }

            // 2. No active device connected. Check if we have a trusted device to reconnect.
            if let trusted = trustedDevice, trusted.autoConnect {
                self.connectionMode = .searching
                self.statusDescription = "Searching for \(trusted.name)..."
                self.isAutoConnecting = true

                // Attempt Hotspot gateway discovery first
                if let gateway = await adbService.detectHotspotGatewayIP() {
                    let connected = try await adbService.connectWireless(ipAddress: gateway, port: 5555)
                    if connected {
                        var updated = trusted
                        updated.lastKnownHotspotIP = gateway
                        self.trustedDevice = updated
                        TrustedDeviceStore.saveOrUpdateDevice(updated)

                        self.connectionMode = .connectedHotspot
                        self.statusDescription = "Auto-connected to Hotspot (\(gateway))"
                        self.isAutoConnecting = false

                        let refreshed = try await adbService.listDevices()
                        if let found = refreshed.first(where: { $0.id.contains(gateway) }) {
                            onDeviceAvailable(found)
                            if updated.autoLaunchMirror {
                                await MirrorSessionManager.shared.startMirroring(device: found, config: config)
                            }
                        }
                        return
                    }
                }

                // Attempt last known Wi-Fi IP
                if let lastIP = trusted.lastKnownIP {
                    let connected = try await adbService.connectWireless(ipAddress: lastIP, port: 5555)
                    if connected {
                        self.connectionMode = .connectedWifi
                        self.statusDescription = "Auto-connected to Wi-Fi (\(lastIP))"
                        self.isAutoConnecting = false

                        let refreshed = try await adbService.listDevices()
                        if let found = refreshed.first(where: { $0.id.contains(lastIP) }) {
                            onDeviceAvailable(found)
                            if trusted.autoLaunchMirror {
                                await MirrorSessionManager.shared.startMirroring(device: found, config: config)
                            }
                        }
                        return
                    }
                }

                // Attempt last known Hotspot IP
                if let lastHotspot = trusted.lastKnownHotspotIP {
                    let connected = try await adbService.connectWireless(ipAddress: lastHotspot, port: 5555)
                    if connected {
                        self.connectionMode = .connectedHotspot
                        self.statusDescription = "Auto-connected to Hotspot (\(lastHotspot))"
                        self.isAutoConnecting = false

                        let refreshed = try await adbService.listDevices()
                        if let found = refreshed.first(where: { $0.id.contains(lastHotspot) }) {
                            onDeviceAvailable(found)
                            if trusted.autoLaunchMirror {
                                await MirrorSessionManager.shared.startMirroring(device: found, config: config)
                            }
                        }
                        return
                    }
                }

                self.isAutoConnecting = false
            }

            self.connectionMode = .disconnected
            self.statusDescription = "Connect via USB cable or phone hotspot to begin."
        } catch {
            self.connectionMode = .disconnected
            self.statusDescription = "ADB scan paused: \(error.localizedDescription)"
        }
    }

    private func isHotspotEndpoint(_ serial: String) async -> Bool {
        if let gateway = await AdbService.shared.detectHotspotGatewayIP(), serial.contains(gateway) {
            return true
        }
        return false
    }
}
