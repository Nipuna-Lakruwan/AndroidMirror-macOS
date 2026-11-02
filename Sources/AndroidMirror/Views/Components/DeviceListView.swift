//
//  DeviceListView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created DeviceListView to display discovered Android devices with real-time
//              status badges (battery level, USB vs Wi-Fi, authorization state).
//  How: Implemented as a SwiftUI List view with selection bindings and refresh triggers.
//

import SwiftUI

public struct DeviceListView: View {
    public let devices: [AndroidDevice]
    @Binding public var selectedDeviceId: String?
    public var onRefresh: () -> Void
    public var onAddWireless: () -> Void

    public init(
        devices: [AndroidDevice],
        selectedDeviceId: Binding<String?>,
        onRefresh: @escaping () -> Void,
        onAddWireless: @escaping () -> Void
    ) {
        self.devices = devices
        self._selectedDeviceId = selectedDeviceId
        self.onRefresh = onRefresh
        self.onAddWireless = onAddWireless
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Devices")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: onAddWireless) {
                    Image(systemName: "wifi.badge.plus")
                }
                .buttonStyle(.plain)
                .help("Connect to device via Wi-Fi IP")

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh device list")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if devices.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cable.connector.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No Devices Connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Connect your Android phone via USB or pair over Wi-Fi.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(devices, id: \.id, selection: $selectedDeviceId) { device in
                    HStack(spacing: 12) {
                        Image(systemName: device.isWireless ? "wifi" : "cable.connector")
                            .font(.system(size: 16))
                            .foregroundStyle(device.state == .device ? .blue : .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.displayName)
                                .font(.body)
                                .fontWeight(selectedDeviceId == device.id ? .semibold : .regular)

                            HStack(spacing: 6) {
                                Text(device.connectionType.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                                if let battery = device.batteryLevel {
                                    HStack(spacing: 2) {
                                        Image(systemName: device.isCharging ? "battery.100.bolt" : "battery.75")
                                        Text("\(battery)%")
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }

                                if device.state != .device {
                                    Text(device.state.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .tag(device.id)
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)
    }
}
