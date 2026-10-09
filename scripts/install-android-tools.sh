#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p /workspace/toolchains/{android-user/cache,pub-cache,gradle,config,cache}
if [ ! -x /workspace/toolchains/flutter/bin/flutter ]; then
  curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz -o /tmp/madrissti-flutter.tar.xz
  python3 - <<'PY'
import hashlib
assert hashlib.file_digest(open('/tmp/madrissti-flutter.tar.xz','rb'),'sha256').hexdigest() == 'af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230'
PY
  tar -xf /tmp/madrissti-flutter.tar.xz -C /workspace/toolchains
fi
if [ ! -x /workspace/toolchains/android-sdk/cmdline-tools/latest/bin/sdkmanager ]; then
  curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/madrissti-android-tools.zip
  python3 - <<'PY'
import hashlib,zipfile
from pathlib import Path
# Google's repository2-1.xml supplies the SHA1 for command-line tools 12.0.
assert hashlib.file_digest(open('/tmp/madrissti-android-tools.zip','rb'),'sha1').hexdigest() == 'd313adb7aedccf6cf0cfca51ec180f0059f5f8f8'
p=Path('/workspace/toolchains/android-sdk/cmdline-tools')
p.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile('/tmp/madrissti-android-tools.zip') as z: z.extractall(p)
(p/'cmdline-tools').rename(p/'latest')
for f in (p/'latest/bin').iterdir(): f.chmod(0o755)
PY
fi
if [ ! -x /workspace/toolchains/jdk/bin/javac ]; then
  curl -fsSL https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_linux_hotspot_21.0.12.1_1.tar.gz -o /tmp/madrissti-jdk.tar.gz
  python3 - <<'VERIFY'
import hashlib
assert hashlib.file_digest(open('/tmp/madrissti-jdk.tar.gz','rb'),'sha256').hexdigest() == 'ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94'
VERIFY
  mkdir -p /workspace/toolchains/jdk
  tar -xf /tmp/madrissti-jdk.tar.gz --strip-components=1 -C /workspace/toolchains/jdk
fi
source scripts/android-env.sh
python3 - <<'PY'
import os,subprocess,urllib.parse
from pathlib import Path
u=urllib.parse.urlparse(os.environ.get('HTTPS_PROXY',''))
base=['/workspace/toolchains/android-sdk/cmdline-tools/latest/bin/sdkmanager','--sdk_root=/workspace/toolchains/android-sdk']
if u.hostname:
    base += ['--proxy=http','--proxy_host='+u.hostname,'--proxy_port='+str(u.port or 80)]
    p=Path('/workspace/toolchains/gradle/gradle.properties')
    if not p.exists():
        p.write_text(f'systemProp.https.proxyHost={u.hostname}\nsystemProp.https.proxyPort={u.port or 80}\nsystemProp.http.proxyHost={u.hostname}\nsystemProp.http.proxyPort={u.port or 80}\nsystemProp.http.nonProxyHosts=localhost|127.*\n')
subprocess.run(base+['--licenses'],input='y\n'*100,text=True,check=True)
subprocess.run(base+['platform-tools','platforms;android-36','build-tools;36.0.0','ndk;28.2.13676358'],input='y\n'*100,text=True,check=True)
PY
cd app
flutter pub get --enforce-lockfile
