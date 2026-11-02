//
//  AndroidDevice.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created AndroidDevice model representing an Android hardware or emulated device,
//              its connection state, battery level, model name, and connection type (USB or Wi-Fi).
//  How: Implemented as an Identifiable, Hashable, and Sendable struct with computed properties.
//

import Foundation

public enum ConnectionType: String, Sendable, CaseIterable {
    case usb = "USB"
    case wifi = "Wi-Fi"
    case unknown = "Unknown"
}

public enum DeviceState: String, Sendable {
    case device = "Authorized"
    case unauthorized = "Unauthorized"
    case offline = "Offline"
    case connecting = "Connecting"
}

public struct AndroidDevice: Identifiable, Hashable, Sendable {
    public let id: String // Serial number or IP:port
    public var modelName: String
    public var manufacturer: String
    public var androidVersion: String
    public var state: DeviceState
    public var connectionType: ConnectionType
    public var batteryLevel: Int?
    public var isCharging: Bool
    public var ipAddress: String?

    public init(
        id: String,
        modelName: String = "Android Device",
        manufacturer: String = "Generic",
        androidVersion: String = "Unknown",
        state: DeviceState = .device,
        connectionType: ConnectionType = .usb,
        batteryLevel: Int? = nil,
        isCharging: Bool = false,
        ipAddress: String? = nil
    ) {
        self.id = id
        self.modelName = modelName
        self.manufacturer = manufacturer
        self.androidVersion = androidVersion
        self.state = state
        self.connectionType = connectionType
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.ipAddress = ipAddress
    }

    public var displayName: String {
        if modelName != "Android Device" && !modelName.isEmpty {
            return modelName
        }
        return id
    }

    public var isWireless: Bool {
        return connectionType == .wifi || id.contains(":")
    }
}
