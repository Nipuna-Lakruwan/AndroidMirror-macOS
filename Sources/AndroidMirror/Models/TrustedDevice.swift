//
//  TrustedDevice.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: TrustedDevice had hardcoded default strings 'Samsung Galaxy S23 Ultra', 'SM-S918B', 'Samsung'.
//  Modified Code: Removed all hardcoded device/brand strings. Defaults are now generic ('Android Device', 'Unknown').
//                 The actual connected device identity is stored dynamically upon connection.
//  How: Replaced hardcoded default parameter values with generic fallbacks.

import Foundation

public struct TrustedDevice: Codable, Identifiable, Sendable, Equatable {
    public var id: String // Serial number or primary identifier
    public var name: String // e.g. Dynamic device display name
    public var model: String // e.g. Dynamic model string
    public var manufacturer: String // Dynamic manufacturer
    public var lastKnownIP: String?
    public var lastKnownHotspotIP: String?
    public var autoConnect: Bool
    public var autoTransitionWireless: Bool
    public var autoLaunchMirror: Bool
    public var lastConnectedAt: Date

    public init(
        id: String,
        name: String = "Android Device",
        model: String = "Generic",
        manufacturer: String = "Android",
        lastKnownIP: String? = nil,
        lastKnownHotspotIP: String? = nil,
        autoConnect: Bool = true,
        autoTransitionWireless: Bool = true,
        autoLaunchMirror: Bool = false,
        lastConnectedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.manufacturer = manufacturer
        self.lastKnownIP = lastKnownIP
        self.lastKnownHotspotIP = lastKnownHotspotIP
        self.autoConnect = autoConnect
        self.autoTransitionWireless = autoTransitionWireless
        self.autoLaunchMirror = autoLaunchMirror
        self.lastConnectedAt = lastConnectedAt
    }
}

public final class TrustedDeviceStore: Sendable {
    private static let storageKey = "com.nipunall.AndroidMirror.TrustedDevices"
    private static let activeDeviceIdKey = "com.nipunall.AndroidMirror.ActiveTrustedDeviceId"

    public static func loadDevices() -> [TrustedDevice] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([TrustedDevice].self, from: data) else {
            return []
        }
        return list
    }

    public static func saveDevices(_ devices: [TrustedDevice]) {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    public static func getPrimaryDevice() -> TrustedDevice? {
        let devices = loadDevices()
        if let activeId = UserDefaults.standard.string(forKey: activeDeviceIdKey),
           let match = devices.first(where: { $0.id == activeId }) {
            return match
        }
        return devices.first
    }

    public static func saveOrUpdateDevice(_ device: TrustedDevice) {
        var devices = loadDevices()
        if let index = devices.firstIndex(where: { $0.id == device.id || $0.model == device.model }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        saveDevices(devices)
        UserDefaults.standard.set(device.id, forKey: activeDeviceIdKey)
    }

    public static func removeDevice(id: String) {
        var devices = loadDevices()
        devices.removeAll(where: { $0.id == id })
        saveDevices(devices)
    }
}
