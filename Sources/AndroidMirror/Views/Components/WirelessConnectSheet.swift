//
//  WirelessConnectSheet.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: Fixed 400x320 sheet causing text truncation, lacked auto-IP detection on appearance,
//                 and left the IP address field blank when USB device was attached.
//  Modified Code: Redesigned sheet with responsive dimensions (460x420), zero text truncation,
//                 automatic asynchronous mobile IP retrieval on appear (supporting both Wi-Fi and Mobile Hotspot),
//                 prominent detected IP display badge, and single-click 'Switch to Wireless & Connect' action.
//  How: Implemented in SwiftUI with .task auto-fetch, dynamic IP pre-population, and wrapped layout.
//

import SwiftUI

public struct WirelessConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let usbDevice: AndroidDevice?
    public var onConnected: () -> Void

    @State private var ipAddress: String = ""
    @State private var port: String = "5555"
    @State private var isConnecting = false
    @State private var isDetectingIP = false
    @State private var detectedSource: String?
    @State private var errorMessage: String?

    public init(usbDevice: AndroidDevice?, onConnected: @escaping () -> Void) {
        self.usbDevice = usbDevice
        self.onConnected = onConnected
        if let ip = usbDevice?.ipAddress, !ip.isEmpty {
            self._ipAddress = State(initialValue: ip)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Connect Wirelessly")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            VStack(alignment: .leading, spacing: 18) {
                Text("Connect your Android device over local Wi-Fi or Mobile Hotspot without requiring a USB cable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // USB Fast Switch Card
                if let usbDevice = usbDevice {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "cable.connector")
                                .foregroundStyle(.blue)
                            Text("Connected via USB: \(usbDevice.displayName)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }

                        if isDetectingIP {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Detecting mobile IP address...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if !ipAddress.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Detected Phone IP: \(ipAddress)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                if let source = detectedSource {
                                    Text("(\(source))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Button(action: enableWirelessAndConnect) {
                            HStack(spacing: 6) {
                                if isConnecting {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "wifi")
                                }
                                Text("Enable Wireless Mode & Connect")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(isConnecting)
                    }
                    .padding(14)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }

                // Manual IP Configuration
                VStack(alignment: .leading, spacing: 10) {
                    Text("Device Network Address")
                        .font(.caption)
                        .fontWeight(.semibold)

                    HStack(spacing: 10) {
                        TextField("Phone IP (e.g. 192.168.1.150 or 10.121.149.15)", text: $ipAddress)
                            .textFieldStyle(.roundedBorder)

                        TextField("Port", text: $port)
                            .frame(width: 70)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let source = detectedSource, !ipAddress.isEmpty {
                        Text("Auto-detected via \(source).")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tip: If connected to your phone's Hotspot, the IP is automatically discovered.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let errorMessage = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                HStack {
                    Spacer()
                    Button("Connect Wirelessly") {
                        connect()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(ipAddress.trimmingCharacters(in: .whitespaces).isEmpty || isConnecting)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 460, idealWidth: 480, minHeight: 380, idealHeight: 420)
        .task {
            await autoDetectDeviceIP()
        }
    }

    private func autoDetectDeviceIP() async {
        isDetectingIP = true

        // 1. Try querying connected USB device directly
        if let device = usbDevice {
            if let ip = await AdbService.shared.queryDeviceIP(serial: device.id), !ip.isEmpty {
                self.ipAddress = ip
                self.detectedSource = "Phone Wi-Fi/Hotspot Interface"
                self.isDetectingIP = false
                return
            }
        }

        // 2. Check if Mac is connected to phone's Wi-Fi hotspot
        if let gateway = await AdbService.shared.detectHotspotGatewayIP(), !gateway.isEmpty {
            self.ipAddress = gateway
            self.detectedSource = "Mobile Hotspot Gateway"
            self.isDetectingIP = false
            return
        }

        self.isDetectingIP = false
    }

    private func enableWirelessAndConnect() {
        guard let device = usbDevice else { return }
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                let targetPort = Int(port) ?? 5555
                // 1. Arm ADB TCP/IP on phone
                try await AdbService.shared.enableTcpIp(serial: device.id, port: targetPort)

                // 2. Query device IP if not yet populated
                var targetIp = ipAddress.trimmingCharacters(in: .whitespaces)
                if targetIp.isEmpty {
                    if let ip = await AdbService.shared.queryDeviceIP(serial: device.id) {
                        targetIp = ip
                        self.ipAddress = ip
                    } else if let gateway = await AdbService.shared.detectHotspotGatewayIP() {
                        targetIp = gateway
                        self.ipAddress = gateway
                    }
                }

                guard !targetIp.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "Could not detect phone IP address. Ensure the phone is connected to Wi-Fi or Mobile Hotspot."
                        self.isConnecting = false
                    }
                    return
                }

                // 3. Connect wirelessly
                let success = try await AdbService.shared.connectWireless(ipAddress: targetIp, port: targetPort)
                await MainActor.run {
                    self.isConnecting = false
                    if success {
                        onConnected()
                        dismiss()
                    } else {
                        self.errorMessage = "Connected TCP/IP on device, but failed to connect to \(targetIp):\(targetPort)."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed: \(error.localizedDescription)"
                    self.isConnecting = false
                }
            }
        }
    }

    private func connect() {
        let trimmedIp = ipAddress.trimmingCharacters(in: .whitespaces)
        let targetPort = Int(port) ?? 5555

        guard !trimmedIp.isEmpty else { return }
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                let success = try await AdbService.shared.connectWireless(ipAddress: trimmedIp, port: targetPort)
                await MainActor.run {
                    self.isConnecting = false
                    if success {
                        onConnected()
                        dismiss()
                    } else {
                        self.errorMessage = "Could not connect to \(trimmedIp):\(targetPort). Ensure USB debugging is enabled and the phone is on the same network."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isConnecting = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
