//
//  AndroidMirror.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: Lacked dedicated Clipboard menu commands.
//  Modified Code: Added system-wide Clipboard menu commands (Paste to Phone Cmd+Shift+V, Copy from Phone Cmd+Shift+C).
//  How: Added CommandMenu("Clipboard") to App commands hierarchy.
//

import SwiftUI

@main
struct AndroidMirrorApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, idealWidth: 980, minHeight: 640, idealHeight: 820)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                // Remove redundant new window menu
            }

            CommandMenu("Device") {
                Button("Home Screen") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { try? await AdbService.shared.sendHomeKey(serial: serial) }
                    }
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("App Switcher") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { try? await AdbService.shared.sendAppSwitchKey(serial: serial) }
                    }
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Expand Notifications") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { try? await AdbService.shared.expandNotifications(serial: serial) }
                    }
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Back") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { try? await AdbService.shared.sendBackKey(serial: serial) }
                    }
                }
                .keyboardShortcut("[", modifiers: .command)

                Divider()

                Button("Lock / Power Display") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { try? await AdbService.shared.sendPowerKey(serial: serial) }
                    }
                }
                .keyboardShortcut("l", modifiers: .command)

                Button("Take Screenshot") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
                        let filename = "Android_Screenshot_\(Int(Date().timeIntervalSince1970)).png"
                        let path = desktop.appendingPathComponent(filename).path
                        Task { try? await AdbService.shared.takeScreenshot(serial: serial, destinationPath: path) }
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandMenu("Clipboard") {
                Button("Paste Mac Clipboard to Phone") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { _ = await ClipboardSyncManager.shared.pasteMacClipboardToPhone(serial: serial) }
                    }
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])

                Button("Copy from Phone") {
                    if let serial = MirrorSessionManager.shared.activeDevice?.id {
                        Task { _ = await ClipboardSyncManager.shared.copyFromPhoneToMac(serial: serial) }
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }
    }
}
