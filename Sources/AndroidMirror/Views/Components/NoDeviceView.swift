//
//  NoDeviceView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created NoDeviceView to present a guided setup tutorial for Android mirroring
//              (enabling Developer Options, toggling USB Debugging, and wireless pairing).
//  How: Implemented as an illustrated SwiftUI onboarding view with actionable buttons.
//

import SwiftUI

public struct NoDeviceView: View {
    public var onScan: () -> Void
    public var onConnectWireless: () -> Void

    public init(onScan: @escaping () -> Void, onConnectWireless: @escaping () -> Void) {
        self.onScan = onScan
        self.onConnectWireless = onConnectWireless
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon Header
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "iphone.and.arrow.forward")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("Connect Your Android Device")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Mirror and control your phone directly from your Mac with zero lag.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Step-by-Step Instructions Card
            VStack(alignment: .leading, spacing: 14) {
                StepRow(
                    stepNumber: "1",
                    title: "Enable Developer Options",
                    detail: "Go to Settings > About phone, and tap 'Build number' 7 times."
                )

                StepRow(
                    stepNumber: "2",
                    title: "Turn On USB Debugging",
                    detail: "Go to Settings > System > Developer options, and toggle 'USB debugging'."
                )

                StepRow(
                    stepNumber: "3",
                    title: "Connect & Authorize",
                    detail: "Connect via USB-C cable and tap 'Always allow from this computer'."
                )
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .frame(maxWidth: 420)

            // Actions
            HStack(spacing: 16) {
                Button(action: onScan) {
                    Label("Scan for Devices", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onConnectWireless) {
                    Label("Connect via Wi-Fi", systemImage: "wifi")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StepRow: View {
    let stepNumber: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(stepNumber)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.blue, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
