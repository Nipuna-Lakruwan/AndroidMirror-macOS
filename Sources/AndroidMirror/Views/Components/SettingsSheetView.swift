//
//  SettingsSheetView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: SettingsSheetView had commercial Pro license status and basic screen off toggle.
//  Modified Code: Converted license section to Open Source Community Edition (FOSS like VLC)
//                 and added comprehensive physical screen touch isolation controls (Virtual Display mode,
//                 Double-Tap Wake suppression, and --no-power-on protection).
//  How: Added toggles for useVirtualDisplay, disableTouchWake, and noPowerOn, and updated header to Open Source.
//

import SwiftUI

public struct SettingsSheetView: View {
    @Binding public var config: MirrorConfig
    @Environment(\.dismiss) private var dismiss

    public init(config: Binding<MirrorConfig>) {
        self._config = config
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Android Mirror Preferences")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            Form {
                Section("Open Source Edition (VLC-Style FOSS)") {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("Free & Open Source")
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text("All Features Unlocked")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Text("Created by Nipuna Lakruwan - Inspired by VLC (VideoLAN)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(LicenseManager.copyrightNotice)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Section("Display & Touch Isolation (Fix Accidental Touches)") {
                    Toggle("Virtual Display Mode (Isolated Session)", isOn: $config.useVirtualDisplay)
                        .help("Creates an independent virtual display on Android 13/14+. The physical phone screen stays completely dark and locked, and physical touches on the phone are completely ignored.")

                    Toggle("Turn Physical Screen Off During Mirror", isOn: $config.turnScreenOff)
                        .help("Keeps your phone screen dark for privacy and battery savings.")

                    Toggle("Suppress Double-Tap Wake on Phone", isOn: $config.disableTouchWake)
                        .help("Temporarily suppresses double-tap-to-wake and ambient gestures during mirroring to prevent accidental screen wakeups when holding or tapping the phone.")

                    Toggle("Prevent Screen Wake on Connect (--no-power-on)", isOn: $config.noPowerOn)
                        .help("Prevents the physical phone screen from lighting up when mirroring begins.")

                    Toggle("Keep Device Awake While Connected", isOn: $config.stayAwake)

                    Toggle("Always On Top", isOn: $config.alwaysOnTop)

                    Toggle("Lock Device When Session Closes", isOn: $config.powerOffOnClose)
                }

                Section("Universal Clipboard") {
                    Toggle("Automatic Clipboard Synchronization", isOn: $config.clipboardAutoSync)
                        .help("Copies and pastes text seamlessly between macOS and your Android device using Cmd+C and Cmd+V.")

                    Toggle("Legacy Keystroke Paste Emulation", isOn: $config.legacyPaste)
                        .help("Injects paste as simulated keystrokes for secure password fields.")
                }

                Section("Media & Audio") {
                    Toggle("Forward Audio to Mac Speakers", isOn: $config.forwardAudio)
                        .help("Routes phone media, games, and system audio to your Mac via low-latency Opus.")
                }

                Section("Quality & Performance") {
                    Picker("Maximum Resolution", selection: $config.maxResolution) {
                        Text("Native (Uncapped)").tag(0)
                        Text("1080p Full HD").tag(1080)
                        Text("1440p Quad HD").tag(1440)
                        Text("720p HD").tag(720)
                    }

                    Picker("Video Bitrate", selection: $config.bitRateMbps) {
                        Text("8 Mbps (Standard)").tag(8)
                        Text("16 Mbps (High Quality)").tag(16)
                        Text("24 Mbps (Ultra High)").tag(24)
                        Text("32 Mbps (Maximum)").tag(32)
                    }

                    Picker("Maximum Frame Rate", selection: $config.maxFps) {
                        Text("30 FPS").tag(30)
                        Text("60 FPS (Smooth)").tag(60)
                        Text("120 FPS (Ultra Smooth)").tag(120)
                    }
                }
            }
            .formStyle(.grouped)
            .padding(10)
        }
        .frame(width: 480, height: 490)
    }
}
