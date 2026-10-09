#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/android-env.sh
cd app
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --debug
