//
//  MirrorConfig.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: MirrorConfig only had turnScreenOff and lacked virtual display and touch suppression settings.
//  Modified Code: Added useVirtualDisplay, disableTouchWake, and noPowerOn to completely prevent physical screen touch interference and wakeups.
//  How: Added boolean properties useVirtualDisplay, disableTouchWake, and noPowerOn with initialization parameters.
//

import Foundation

public struct MirrorConfig: Sendable, Equatable {
    // Replicates Apple's iPhone Mirroring locked-screen behavior:
    // Physical screen turns black and locks while in active use on Mac.
    public var turnScreenOff: Bool = true
    
    // Virtual Display mode: Creates an isolated offscreen display session
    // Physical phone screen stays dark/idle and physical touches to phone glass are ignored.
    public var useVirtualDisplay: Bool = false

    // Temporarily suppresses double-tap-to-wake and ambient touch gestures while mirroring
    public var disableTouchWake: Bool = true

    // Prevents scrcpy from waking up the physical device screen upon launching session
    public var noPowerOn: Bool = true

    // Prevents device from entering deep sleep while mirroring
    public var stayAwake: Bool = true
    
    // Audio forwarding to Mac speakers
    public var forwardAudio: Bool = true
    
    // Keep mirroring window floating on top
    public var alwaysOnTop: Bool = false

    // Universal Clipboard synchronization between Mac and Android
    public var clipboardAutoSync: Bool = true

    // Inject clipboard text as simulated keystrokes for secure input fields
    public var legacyPaste: Bool = false
    
    // Video streaming parameters
    public var maxResolution: Int = 1440 // 0 for native, 1080, 1440, etc.
    public var bitRateMbps: Int = 16 // 8, 16, 24 Mbps
    public var maxFps: Int = 60 // 30, 60, 120 FPS
    
    // Lock / turn screen off when session closes
    public var powerOffOnClose: Bool = false
    
    // Window scale factor
    public var windowScale: Double = 1.0

    public init(
        turnScreenOff: Bool = true,
        useVirtualDisplay: Bool = false,
        disableTouchWake: Bool = true,
        noPowerOn: Bool = true,
        stayAwake: Bool = true,
        forwardAudio: Bool = true,
        alwaysOnTop: Bool = false,
        clipboardAutoSync: Bool = true,
        legacyPaste: Bool = false,
        maxResolution: Int = 1440,
        bitRateMbps: Int = 16,
        maxFps: Int = 60,
        powerOffOnClose: Bool = false,
        windowScale: Double = 1.0
    ) {
        self.turnScreenOff = turnScreenOff
        self.useVirtualDisplay = useVirtualDisplay
        self.disableTouchWake = disableTouchWake
        self.noPowerOn = noPowerOn
        self.stayAwake = stayAwake
        self.forwardAudio = forwardAudio
        self.alwaysOnTop = alwaysOnTop
        self.clipboardAutoSync = clipboardAutoSync
        self.legacyPaste = legacyPaste
        self.maxResolution = maxResolution
        self.bitRateMbps = bitRateMbps
        self.maxFps = maxFps
        self.powerOffOnClose = powerOffOnClose
        self.windowScale = windowScale
    }
}
