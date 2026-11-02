//
//  TrustedDeviceCardView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: Had hardcoded fallback string 'Samsung Galaxy S23 Ultra'.
//  Modified Code: Removed hardcoded fallback. Displays dynamic paired device name or 'No Paired Device'.
//  How: Updated Text view condition and file description.
//

import SwiftUI

public struct TrustedDeviceCardView: View {
    public let trustedDevice: TrustedDevice?
    public let connectionMode: ConnectionMode
    public let statusText: String
    public var onManualReconnect: () -> Void
    public var onForgetDevice: () -> Void

    public init(
        trustedDevice: TrustedDevice?,
        connectionMode: ConnectionMode,
        statusText: String,
        onManualReconnect: @escaping () -> Void,
        onForgetDevice: @escaping () -> Void
    ) {
        self.trustedDevice = trustedDevice
        self.connectionMode = connectionMode
        self.statusText = statusText
        self.onManualReconnect = onManualReconnect
        self.onForgetDevice = onForgetDevice
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Device Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(badgeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(badgeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(trustedDevice?.name ?? "No Paired Device")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(badgeColor)
                            .frame(width: 7, height: 7)

                        Text(trustedDevice == nil ? "Connect via USB or Wi-Fi to automatically save device" : statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if connectionMode == .disconnected || connectionMode == .searching {
                    Button(action: onManualReconnect) {
                        Label("Connect", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if let trusted = trustedDevice {
                Divider()

                HStack(spacing: 16) {
                    if let ip = trusted.lastKnownHotspotIP {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Hotspot Gateway")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(ip)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    if let ip = trusted.lastKnownIP {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Wi-Fi IP")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(ip)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()

                    Button(role: .destructive, action: onForgetDevice) {
                        Text("Forget")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(badgeColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var badgeColor: Color {
        switch connectionMode {
        case .connectedUsb, .connectedWifi, .connectedHotspot:
            return .green
        case .searching:
            return .blue
        case .disconnected:
            return .secondary
        }
    }

    private var iconName: String {
        switch connectionMode {
        case .connectedUsb:
            return "cable.connector"
        case .connectedHotspot:
            return "personalhotspot"
        case .connectedWifi:
            return "wifi"
        case .searching:
            return "antenna.radiowaves.left.and.right"
        case .disconnected:
            return "iphone.gen3"
        }
    }
}
