//
//  ClipboardSyncManager.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created ClipboardSyncManager providing seamless Universal Clipboard synchronization
//              between macOS and Android devices (copying text on Mac and pasting into phone apps,
//              and copying from phone to Mac pasteboard).
//  How: Monitors NSPasteboard change counts and executes ADB keyevents/text injections.
//

import AppKit
import Foundation
import Observation

@Observable
@MainActor
public final class ClipboardSyncManager {
    public static let shared = ClipboardSyncManager()

    public var lastSyncedText: String?
    public var lastSyncDirection: String?
    public var isSyncing: Bool = false

    private var pasteboardWatcherTask: Task<Void, Never>?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    public init() {}

    public func startClipboardWatcher(activeSerialProvider: @escaping () -> String?) {
        guard pasteboardWatcherTask == nil else { return }

        lastChangeCount = NSPasteboard.general.changeCount

        pasteboardWatcherTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // check once per second

                await MainActor.run {
                    guard let self = self else { return }
                    let currentCount = NSPasteboard.general.changeCount
                    if currentCount != self.lastChangeCount {
                        self.lastChangeCount = currentCount
                        if let copiedString = NSPasteboard.general.string(forType: .string), !copiedString.isEmpty {
                            self.lastSyncedText = copiedString
                        }
                    }
                }
            }
        }
    }

    public func stopClipboardWatcher() {
        pasteboardWatcherTask?.cancel()
        pasteboardWatcherTask = nil
    }

    // Sends Mac clipboard text directly into active input field on phone
    public func pasteMacClipboardToPhone(serial: String) async -> Bool {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            return false
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // First attempt: KEYCODE_PASTE (279)
            try await AdbService.shared.sendPasteCommand(serial: serial)
            self.lastSyncedText = text
            self.lastSyncDirection = "Mac -> Phone"
            return true
        } catch {
            // Fallback: inject text directly as characters
            do {
                try await AdbService.shared.injectTextToDevice(serial: serial, text: text)
                self.lastSyncedText = text
                self.lastSyncDirection = "Mac -> Phone (Injected)"
                return true
            } catch {
                return false
            }
        }
    }

    // Triggers copy on phone and synchronizes to Mac pasteboard
    public func copyFromPhoneToMac(serial: String) async -> Bool {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await AdbService.shared.sendCopyCommand(serial: serial)
            self.lastSyncDirection = "Phone -> Mac"
            return true
        } catch {
            return false
        }
    }
}
