# Development setup

Use this existing checkout; cloud tasks are isolated and require no additional Git worktree.

From the repository root:

```sh
bash scripts/install.sh
PYTHONPATH=backend .venv/bin/pytest -q
```

Set `DEMO_ACCESS_CODE` securely in the backend process environment. `.env.example` documents configuration names; `.env` is ignored but is not automatically loaded. Never place credentials in Flutter assets, source, command output or version control.

```sh
PYTHONPATH=backend .venv/bin/uvicorn tutor.main:create_app --factory --host 127.0.0.1 --port 8000 --workers 1
```

`GET /health` reports backend health and explicitly unavailable inference/voice. `/docs` exposes OpenAPI. Authenticate with `POST /v1/demo/auth`, then use the returned bearer token for catalogue/session routes. Each sign-in currently represents a separate fictional identity; resumable identity and presenter auth are future work.

## Flutter and Android build

Installed toolchain: Flutter stable 3.47.7, Dart 3.13.5, Android SDK/target 36, build tools 36.0.0 and Temurin JDK 21.0.12.1 (including javac). Minimum Android version is API 29 (Android 10). Flutter archive SHA256 and Android command-line tools checksum were verified against official release metadata. The Android project and app dependency lockfile are committed.

From the repository root:

```sh
bash scripts/install-android-tools.sh
bash scripts/build-apk.sh
```

The toolchain is retained outside the checkout at `/workspace/toolchains`. The install script reuses it and verifies downloaded archives when installing it afresh. `scripts/android-env.sh` sets workspace cache paths and disables tooling analytics. Gradle is limited to two workers and a 3 GiB heap. Java downloads use the provided HTTPS proxy without extracting credentials. The JDK uses the system Java trust store to preserve the environment certificate authorities.

Dart analysis still uses `/home/agent/.dartServer`; in a read-only home sandbox, grant write access to that specific cache directory before analysis. Do not change HOME or disable TLS/checksum verification.

The APK is a debug-signed development build, not a production release. No release signing key is configured. Android scaffold has no microphone permission because live voice is not implemented. Do not add permissions before implementing their actual use. APK functionality is bundled Arabic lessons and fraction-bar examples; no backend login or AI connection is wired into this client.

Live model transport remains the next proof gate. Verify current official OpenAI Realtime documentation and account availability before implementing provider calls. `REALTIME_MODEL=gpt-realtime` is a candidate, not a tested model. `TUTOR_PROVIDER_KEY` documents a future backend-only credential and is not consumed by this foundation. Supply credentials through secure environment settings, never chat.

Use HTTPS for a shared backend demonstration. Android emulator host routing differs from physical-device networking; localhost on a tablet is not the developer's computer. Test microphone denial, interruption, cancellation and text alternatives on a physical tablet before claiming the voice gate passed.
