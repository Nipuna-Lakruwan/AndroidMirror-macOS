//
//  MainView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: Included commercial Pro upgrade button and license activation sheet.
//  Modified Code: Replaced commercial Pro elements with Open Source FOSS attribution and AboutSheetView,
//                 and added status feedback for Virtual Display and touch-wake suppression.
//  How: Replaced showLicenseSheet with showAboutSheet, updated toolbar pill to Open Source, and updated footer.
//

import SwiftUI

public struct MainView: View {
    @State private var devices: [AndroidDevice] = []
    @State private var selectedDeviceId: String?
    @State private var config = MirrorConfig()
    @State private var isScanning = false
    @State private var showSettings = false
    @State private var showWirelessSheet = false
    @State private var showAboutSheet = false
    @State private var toastMessage: String?

    private var sessionManager = MirrorSessionManager.shared
    private var autoConn = AutoConnectionManager.shared
    private var licenseManager = LicenseManager.shared

    public init() {}

    private var selectedDevice: AndroidDevice? {
        if let id = selectedDeviceId {
            return devices.first { $0.id == id }
        }
        return devices.first
    }

    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                DeviceListView(
                    devices: devices,
                    selectedDeviceId: $selectedDeviceId,
                    onRefresh: {
                        Task { await scanForDevices() }
                    },
                    onAddWireless: {
                        showWirelessSheet = true
                    }
                )

                Divider()

                // Persistent Pairing Summary
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.blue)
                        Text("Auto-Connect Enabled")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    Text(autoConn.statusDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))

                // Commercial Copyright Attribution
                VStack(spacing: 2) {
                    Divider()
                    Text(LicenseManager.copyrightNotice)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
            }
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Trusted Device Card (Primary Paired Device)
                        TrustedDeviceCardView(
                            trustedDevice: autoConn.trustedDevice,
                            connectionMode: autoConn.connectionMode,
                            statusText: autoConn.statusDescription,
                            onManualReconnect: {
                                Task { await scanForDevices() }
                            },
                            onForgetDevice: {
                                if let id = autoConn.trustedDevice?.id {
                                    TrustedDeviceStore.removeDevice(id: id)
                                    autoConn.trustedDevice = nil
                                    showToast("Removed trusted device pairing.")
                                }
                            }
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        if devices.isEmpty {
                            NoDeviceView(
                                onScan: {
                                    Task { await scanForDevices() }
                                },
                                onConnectWireless: {
                                    showWirelessSheet = true
                                }
                            )
                            .padding(.top, 8)
                        } else if let device = selectedDevice {
                            deviceDetailView(device: device)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Connection Mode Status Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusPillColor)
                        .frame(width: 8, height: 8)
                    Text(autoConn.connectionMode.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())

                if let device = selectedDevice {
                    Button(action: {
                        toggleMirroring(for: device)
                    }) {
                        if sessionManager.isSessionActive {
                            Label("Stop Mirroring", systemImage: "stop.fill")
                                .foregroundStyle(.red)
                        } else {
                            Label("Start Mirroring", systemImage: "play.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .help(sessionManager.isSessionActive ? "Stop active mirroring session" : "Start mirroring phone display")
                }

                Button(action: { showWirelessSheet = true }) {
                    Label("Wireless Pairing", systemImage: "wifi")
                }
                .help("Connect over Wi-Fi / Hotspot")

                // Open Source FOSS Attribution (VLC Style)
                Button(action: { showAboutSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("Open Source")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("About Android Mirror (Free & Open Source Software by Nipuna Lakruwan)")

                Button(action: { showSettings = true }) {
                    Label("Preferences", systemImage: "gearshape")
                }
                .help("Mirroring Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView(config: $config)
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheetView()
        }
        .sheet(isPresented: $showWirelessSheet) {
            WirelessConnectSheet(
                usbDevice: devices.first(where: { !$0.isWireless }),
                onConnected: {
                    Task { await scanForDevices() }
                }
            )
        }
        .task {
            // Initial scan
            await scanForDevices()

            // Start clipboard watcher for cross-device copy-paste
            ClipboardSyncManager.shared.startClipboardWatcher {
                self.selectedDeviceId
            }

            // Start continuous auto-connection background watcher
            autoConn.startBackgroundPolling(config: config) { activeDevice in
                Task { @MainActor in
                    if !self.devices.contains(where: { $0.id == activeDevice.id }) {
                        self.devices.append(activeDevice)
                    }
                    if self.selectedDeviceId == nil {
                        self.selectedDeviceId = activeDevice.id
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = toastMessage {
                Text(toast)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThickMaterial, in: Capsule())
                    .shadow(radius: 4)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var statusPillColor: Color {
        switch autoConn.connectionMode {
        case .connectedUsb, .connectedWifi, .connectedHotspot:
            return .green
        case .searching:
            return .blue
        case .disconnected:
            return .gray
        }
    }

    @ViewBuilder
    private func deviceDetailView(device: AndroidDevice) -> some View {
        VStack(spacing: 16) {
            // Main Phone Canvas
            DeviceBezelView(
                deviceName: device.displayName,
                isSessionActive: sessionManager.isSessionActive
            ) {
                if sessionManager.isSessionActive {
                    VStack(spacing: 12) {
                        Image(systemName: "display")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)

                        Text("Mirroring Active")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(device.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.gray)

                        if config.useVirtualDisplay {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.split.2x1.fill")
                                Text("Virtual Display Isolation Active (Physical touches ignored)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .padding(.top, 4)
                        } else if config.turnScreenOff {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.fill")
                                Text("Physical screen dark & touch protected")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        }
                    }
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text(device.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)

                        VStack(spacing: 4) {
                            Text("\(device.manufacturer) - Android \(device.androidVersion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let battery = device.batteryLevel {
                                Text("Battery: \(battery)% \(device.isCharging ? "(Charging)" : "")")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            if let ip = device.ipAddress, !ip.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "wifi")
                                    Text("IP: \(ip)")
                                }
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            }
                        }

                        Button(action: {
                            toggleMirroring(for: device)
                        }) {
                            Label("Launch Mirroring", systemImage: "play.fill")
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 8)

                        // Save as Primary Device button
                        if autoConn.trustedDevice?.id != device.id {
                            Button(action: {
                                var trusted = TrustedDevice(
                                    id: device.id,
                                    name: device.displayName,
                                    model: device.modelName,
                                    manufacturer: device.manufacturer
                                )
                                trusted.lastKnownIP = device.ipAddress
                                autoConn.setTrustedDevice(trusted)
                                showToast("Saved \(device.displayName) as primary auto-connect device.")
                            }) {
                                Label("Remember as Default Phone", systemImage: "star.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                            .padding(.top, 4)
                        }
                    }
                }
            }

            // Quick Control Bar (Home, Recents, Notifications, Power, Clipboard)
            ControlBarView(
                serial: device.id,
                isSessionActive: sessionManager.isSessionActive,
                onScreenshotTaken: { path in
                    showToast("Screenshot saved to Desktop: \(URL(fileURLWithPath: path).lastPathComponent)")
                },
                onClipboardPasted: {
                    showToast("Pasted Mac clipboard to phone")
                }
            )
        }
        .padding(.vertical, 8)
    }

    private func toggleMirroring(for device: AndroidDevice) {
        if sessionManager.isSessionActive {
            sessionManager.stopMirroring()
        } else {
            Task {
                await sessionManager.startMirroring(device: device, config: config)
            }
        }
    }

    private func scanForDevices() async {
        isScanning = true
        do {
            let foundDevices = try await AdbService.shared.listDevices()
            await MainActor.run {
                self.devices = foundDevices
                if self.selectedDeviceId == nil || !foundDevices.contains(where: { $0.id == self.selectedDeviceId }) {
                    self.selectedDeviceId = foundDevices.first?.id
                }
                self.isScanning = false
            }
        } catch {
            await MainActor.run {
                self.isScanning = false
                showToast("Scan failed: \(error.localizedDescription)")
            }
        }
    }

    private func showToast(_ text: String) {
        withAnimation {
            self.toastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                if self.toastMessage == text {
                    self.toastMessage = nil
                }
            }
        }
    }
}
