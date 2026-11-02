# Source review — 2 November 2026

This review describes the source at baseline `d68d253`. Repository documentation updates do not fix the runtime findings below.

## Verified

- Local debug build and `swift test` succeed with Swift 6.4.2 on Apple Silicon.
- The only test is an empty Swift Testing example.
- Read-only ADB enumeration and model/version queries work against one authorized wireless device.
- scrcpy 4.1 is installed locally. Its help documents the options used by the session manager.
- The SwiftUI phone canvas is a status placeholder. Video rendering belongs to the separate scrcpy process.

## Prioritized follow-up

1. **Preserve settings:** `AdbService.setTouchWakeSuppression` writes `0` on start and `1` on exit. Capture each original value, including an absent key, and restore it after normal exit and launch failure. Document crash/disconnect recovery.
2. **Protect session state:** a scrcpy termination handler reads mutable current-session fields. An old process can clear a replacement session or restore the wrong device. Bind cleanup to the process/session identity and serialize stop/start.
3. **Fix subprocess I/O:** `AdbService.runProcess` waits for exit before draining stdout/stderr, which can deadlock when a pipe fills. It also blocks its actor executor. Drain both streams while running and add timeout/cancellation handling.
4. **Implement clipboard outcomes:** the app paste action reads Mac text but initially sends only Android's paste key. Successful key injection does not mean that text reached Android. The copy action does not read the phone clipboard. Use a supported transfer path and truthful status feedback.
5. **Honor device and wireless preferences:** USB discovery enables TCP/IP without checking `autoTransitionWireless`. Saved-device matching uses model as well as ID, so two phones of the same model can overwrite each other. Gateway detection is not phone identity verification.
6. **Refresh preferences:** background polling captures the initial `MirrorConfig`; later preference edits may not reach automatic launches. Pass current configuration when starting a session.
7. **Harden packaging:** the build script replaces the installed bundle and suppresses signing failures. Add build-only packaging, verify signing, and document notarization separately before distributing binaries.
8. **Add meaningful coverage:** replace the placeholder with behavior tests for device parsing, command construction, session ownership, settings restoration and same-model device persistence. Hardware checks should cover video/audio/clipboard and disconnect recovery without publishing personal data.

No phone screenshots, clipboard contents, private files or device identifiers were collected for this review. Actual mirroring and performance remain unverified.
