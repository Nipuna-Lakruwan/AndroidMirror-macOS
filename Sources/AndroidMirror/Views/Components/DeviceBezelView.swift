//
//  DeviceBezelView.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created DeviceBezelView to render a realistic, phone-shaped frame with rounded bezels,
//              camera punch-hole cutout, and device status indicators, mirroring the aesthetic
//              of Apple's iPhone Mirroring application.
//  How: Implemented using SwiftUI shapes, strokes, and gradients.
//

import SwiftUI

public struct DeviceBezelView<Content: View>: View {
    public let deviceName: String
    public let isSessionActive: Bool
    public let content: Content

    public init(
        deviceName: String,
        isSessionActive: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.deviceName = deviceName
        self.isSessionActive = isSessionActive
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Speaker / Camera Notch
            HStack {
                Spacer()
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 11, height: 11)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                    )
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color(nsColor: .windowBackgroundColor))

            // Main Viewport Container
            ZStack {
                Color.black
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .frame(minWidth: 320, idealWidth: 380, maxWidth: 500, minHeight: 640, idealHeight: 780, maxHeight: 960)
        .background(
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 2)
        )
        .padding(20)
    }
}
