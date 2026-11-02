//
//  ControlBarView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: ControlBarView lacked clipboard paste button.
//  Modified Code: Added 'Paste to Phone' button triggering ClipboardSyncManager cross-device paste.
//  How: Added button and triggerPasteToPhone function invoking ClipboardSyncManager.

import SwiftUI

public struct ControlBarView: View {
    public let serial: String?
    public let isSessionActive: Bool
    public var onScreenshotTaken: ((String) -> Void)?
    public var onClipboardPasted: (() -> Void)?

    @State private var isExecutingAction = false

    public init(
        serial: String?,
        isSessionActive: Bool,
        onScreenshotTaken: ((String) -> Void)? = nil,
        onClipboardPasted: (() -> Void)? = nil
    ) {
        self.serial = serial
        self.isSessionActive = isSessionActive
        self.onScreenshotTaken = onScreenshotTaken
        self.onClipboardPasted = onClipboardPasted
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Back Action
            Button(action: triggerBack) {
                Label("Back", systemImage: "arrow.left")
            }
            .help("Back (Cmd + [)")
            .keyboardShortcut("[", modifiers: .command)

            // Home Action (Cmd+1 matching iPhone Mirroring)
            Button(action: triggerHome) {
                Label("Home", systemImage: "circle.circle")
            }
            .help("Home Screen (Cmd + 1)")
            .keyboardShortcut("1", modifiers: .command)

            // App Switcher (Cmd+2 matching iPhone Mirroring)
            Button(action: triggerAppSwitch) {
                Label("Recents", systemImage: "square.stack.3d.down.forward")
            }
            .help("App Switcher (Cmd + 2)")
            .keyboardShortcut("2", modifiers: .command)

            Divider()
                .frame(height: 18)

            // Clipboard Paste to Phone
            Button(action: triggerPasteToPhone) {
                Label("Paste to Phone", systemImage: "doc.on.clipboard")
            }
            .help("Paste Mac Clipboard into Phone (Cmd + Shift + V)")
            .keyboardShortcut("v", modifiers: [.command, .shift])

            // Notifications Pull Down
            Button(action: triggerNotifications) {
                Label("Notifications", systemImage: "bell.fill")
            }
            .help("Expand Notifications (Cmd + 3)")
            .keyboardShortcut("3", modifiers: .command)

            // Volume Controls
            Button(action: triggerVolumeDown) {
                Label("Volume Down", systemImage: "speaker.minus.fill")
            }
            .help("Volume Down")

            Button(action: triggerVolumeUp) {
                Label("Volume Up", systemImage: "speaker.plus.fill")
            }
            .help("Volume Up")

            Divider()
                .frame(height: 18)

            // Screenshot Action
            Button(action: triggerScreenshot) {
                Label("Screenshot", systemImage: "camera.fill")
            }
            .help("Take Device Screenshot")

            // Power / Lock Toggle
            Button(action: triggerPower) {
                Label("Lock/Power", systemImage: "power")
            }
            .help("Toggle Device Power / Lock (Cmd + L)")
            .keyboardShortcut("l", modifiers: .command)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(!isSessionActive || serial == nil || isExecutingAction)
    }

    private func triggerPasteToPhone() {
        guard let serial = serial else { return }
        executeAdbTask {
            let ok = await ClipboardSyncManager.shared.pasteMacClipboardToPhone(serial: serial)
            if ok {
                await MainActor.run {
                    onClipboardPasted?()
                }
            }
        }
    }

    private func triggerBack() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.sendBackKey(serial: serial)
        }
    }

    private func triggerHome() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.sendHomeKey(serial: serial)
        }
    }

    private func triggerAppSwitch() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.sendAppSwitchKey(serial: serial)
        }
    }

    private func triggerNotifications() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.expandNotifications(serial: serial)
        }
    }

    private func triggerVolumeUp() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.sendVolumeUp(serial: serial)
        }
    }

    private func triggerVolumeDown() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.sendVolumeDown(serial: serial)
        }
    }

    private func triggerPower() {
        guard let serial = serial else { return }
        executeAdbTask {
            try await AdbService.shared.sendPowerKey(serial: serial)
        }
    }

    private func triggerScreenshot() {
        guard let serial = serial else { return }
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Android_Screenshot_\(formatter.string(from: Date())).png"
        let saveUrl = desktop.appendingPathComponent(filename)

        executeAdbTask {
            try await AdbService.shared.takeScreenshot(serial: serial, destinationPath: saveUrl.path)
            await MainActor.run {
                onScreenshotTaken?(saveUrl.path)
            }
        }
    }

    private func executeAdbTask(_ block: @escaping () async throws -> Void) {
        isExecutingAction = true
        Task {
            do {
                try await block()
            } catch {
                print("Failed ADB key action: \(error)")
            }
            await MainActor.run {
                isExecutingAction = false
            }
        }
    }
}
