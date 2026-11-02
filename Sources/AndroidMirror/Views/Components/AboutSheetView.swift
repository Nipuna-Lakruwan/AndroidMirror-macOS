//
//  AboutSheetView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: LicenseActivationSheet displayed a commercial paywall and key input form.
//  Added Code: Created AboutSheetView showcasing Android Mirror as 100% Free and Open Source Software (FOSS)
//              like VLC (VideoLAN), honoring Nipuna Lakruwan as the author and copyright holder.
//  How: Built with SwiftUI presenting open-source project info, author attribution, and unlocked features list.
//

import SwiftUI

public struct AboutSheetView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // App Icon & Title
            VStack(spacing: 10) {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 10)

                Text("Android Mirror")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version 1.0.0 (Open Source Edition)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Free & Open Source Software (FOSS)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.12), in: Capsule())
            }

            // VLC Philosophy Card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("VLC-Style Open Source Spirit")
                        .font(.headline)
                }

                Text("Like VLC (VideoLAN), Android Mirror is designed to be free, reliable, and respectful of your privacy. There are no paywalls, no activation keys, no tracking, and no subscriptions.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    featureRow(icon: "checkmark.circle.fill", text: "Universal Bidirectional Clipboard (Mac to Phone & Phone to Mac)")
                    featureRow(icon: "checkmark.circle.fill", text: "Isolated Virtual Display Mode (Physical Screen Stays Dark & Off)")
                    featureRow(icon: "checkmark.circle.fill", text: "Full HD & Quad HD 1440p 60/120 FPS Low Latency")
                    featureRow(icon: "checkmark.circle.fill", text: "Native Opus Audio Forwarding to Mac Speakers")
                    featureRow(icon: "checkmark.circle.fill", text: "Automatic Wireless & Hotspot Auto-Connect")
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

            // Author & Copyright
            VStack(spacing: 4) {
                Text("Created by Nipuna Lakruwan")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Copyright © 2026 Nipuna Lakruwan. All rights reserved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Released under the MIT Open Source License")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Dismiss Button
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.bottom, 8)
        }
        .padding(24)
        .frame(width: 520)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}
