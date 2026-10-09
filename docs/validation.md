# Validation status

Backend unit/API integration: 14 tests passed using isolated SQLite databases and test-only demo codes. Covers unauthorized reads, bad-code rate limits, invalid lesson/version/block selections, session ownership, stale revisions, lesson representation restrictions, session end/delete, explicit live-provider unavailability, exact equivalent fractions, invalid rationals and excess tool arguments.

These tests do not validate live AI, audio, package import, evidence assessment or APK behaviour. Flutter static analysis passes. The Arabic catalogue widget test passes while scrolling through all three lessons at 200% text size. The Android debug APK build passes; its APK v2 signature verifies. Physical-device accessibility and latency acceptance remain unrun. No learner trial, model availability test or Madristi integration took place.

Next milestone: prove the authenticated voice/tool spike with secure backend credentials and a physical tablet. Continue package import, activity assessment, presenter permissions and retention only with explicit status for each acceptance criterion.

## Debug APK

Artifact: `artifacts/Madrissti-debug.apk` (generated output, not committed).
Package: `org.madrissti.madrissti_prototype`; version 0.1.0, code 1.
Minimum SDK 29 (Android 10); target SDK 36. ABIs: arm64-v8a, armeabi-v7a, x86_64.
SHA256: `5d04bf27f97b6010388250c944bfaa077ab761844af8fc2e259739d8739a9f9c`.

APK signature verified with Android apksigner. All three lesson assets are present. A scan found no environment files, keystores or standard provider-key patterns in the APK; this is not a comprehensive security audit. No device installation or launch has been tested. SDK, NDK and JDK are installed; a Java-runtime-only build failure was resolved by installing checksum-verified Temurin JDK 21.0.12.1. The toolchain installation script was rerun successfully, and frozen Flutter dependency resolution passes.
