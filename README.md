# Madrissti educational prototype

Arabic-first Flutter and FastAPI foundations for an independent Grade 4 mathematics tutor. Original demonstration lessons: equal parts, unit-fraction comparison using the same whole, and equal sharing. Content awaits educator review. This is not connected to Madristi.

## Current implementation

The backend serves authenticated course content, persists lesson sessions in SQLite, enforces ownership and context revisions, validates fraction-bar requests, and ends/deletes sessions. Exact rational checks use Python fractions. Authentication tokens are memory-only and expire after 15 minutes; restart requires signing in again. Demo codes must be server-configured and are never embedded in the client.

The Flutter source displays bundled Arabic lessons and same-whole fraction bars with semantic descriptions. It is an offline content foundation, not yet connected to backend authentication or tutoring. Full Android project generation, dependency resolution, analysis and widget tests remain blocked by the missing Flutter SDK.

Live AI, voice, attempts/evidence assessment, package import, presenter authorization, reconnect and retention jobs are **not implemented**. `/realtime` explicitly returns unavailable; there is no canned tutor fallback. No APK has been produced.

See [setup](docs/setup.md), [validation](docs/validation.md) and [reference decisions](docs/reference-decisions.md).
