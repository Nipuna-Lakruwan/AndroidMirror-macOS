//
//  LicenseManager.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: Enforced commercial Pro license activation, key verification, and receipt cryptography.
//  Modified Code: Completely removed commercial paywall and key restrictions to make Android Mirror
//                 a 100% Free and Open Source Software (FOSS) application like VLC (VideoLAN),
//                 permanently unlocking all features for all users with Nipuna Lakruwan copyright.
//  How: Permanently set isPro to true, removed key validation routines, and exposed open-source attribution metadata.
//

import Foundation
import Observation

@Observable
@MainActor
public final class LicenseManager {
    public static let shared = LicenseManager()

    public static let appName = "Android Mirror"
    public static let appVersion = "1.0.0"
    public static let developerName = "Nipuna Lakruwan"
    public static let copyrightNotice = "Copyright © 2026 Nipuna Lakruwan. All rights reserved."
    public static let licenseType = "Free and Open Source Software (MIT License)"
    public static let projectPhilosophy = "Inspired by VLC (VideoLAN): Completely free, open source, and privacy-respecting forever. No subscriptions, no ads, no feature paywalls."

    // All features are permanently unlocked for everyone like VLC
    public var isPro: Bool = true
    public var editionName: String = "Open Source Community Edition"

    public init() {
        // Free and open source out of the box
        self.isPro = true
    }
}
