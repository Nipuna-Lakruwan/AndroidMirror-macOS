# Contributing

Build with `swift build` and run `swift test` from the repository root. Use `swift build -c release` to check the release configuration without replacing the installed app. See the README for dependency and toolchain requirements.

Keep changes focused and describe the observed problem, resulting behavior and validation in your pull request. The existing test is a placeholder; add regression coverage for behavior you change where practical.

For device testing, record the Mac architecture, macOS, Swift, scrcpy and Android versions and distinguish USB from wireless results. Confirm intended changes before testing settings, clipboard or input on a personal phone. Check original settings after session exit, failure and reconnect.

Do not include ADB serial numbers, phone IP addresses, pairing codes, private clipboard text, notifications or personal phone screenshots in issues, logs or pull requests. Use synthetic examples and redact diagnostics before sharing them.

Report bugs with reproduction steps, expected and actual behavior, versions and sanitized error output. Avoid attaching phone content unless it is a deliberately prepared demonstration.
