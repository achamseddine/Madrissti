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

## Flutter prerequisite and next proof gate

Allow `storage.googleapis.com` in environment settings and install a checksum-verified stable Flutter SDK from official release metadata. Record the installed Flutter/Dart versions, resolve `app/pubspec.yaml`, and commit `app/pubspec.lock`. No Flutter version or lockfile is claimed until this actually runs.

After the SDK is available, from `app/` generate Android scaffolding without replacing the existing Dart source:

```sh
flutter create --platforms=android --project-name madrissti_prototype --org org.madrissti .
flutter pub get
flutter analyze
flutter test
```

Set Android minSdk to 29 and add only INTERNET and microphone permissions when implementing the voice spike. Keep API keys backend-only. Configure Android SDK with Flutter's current supported Android tooling and accept the required licenses. Run `flutter doctor -v` before `flutter build apk --debug`; debug APK output is `app/build/app/outputs/flutter-apk/app-debug.apk`. Release signing is not configured.

Implement and verify the live provider transport against current official OpenAI Realtime documentation before claiming AI availability. `REALTIME_MODEL=gpt-realtime` is a candidate, not an account-verified model. `TUTOR_PROVIDER_KEY` is reserved for future backend provider configuration and is not read by this foundation. Supply secrets through secure environment settings, never chat.

Use an HTTPS backend for device/shared demonstrations. Android emulator host routing differs from physical-device networking. Do not enable broad cleartext exceptions in release builds. Test microphone denial, interruption, cancellation and text alternatives on a real tablet before completing the voice gate.
