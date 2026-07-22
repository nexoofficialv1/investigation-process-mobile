#!/usr/bin/env python3
from pathlib import Path
import re
import sys

candidates = [
    Path("android/app/build.gradle.kts"),
    Path("android/app/build.gradle"),
]
target = next((path for path in candidates if path.exists()), None)
if target is None:
    print("Android Gradle file not found; run after `flutter create . --platforms=android`.")
    raise SystemExit(1)

text = target.read_text(encoding="utf-8")
original = text

if target.suffix == ".kts":
    text = re.sub(
        r"minSdk\s*=\s*flutter\.minSdkVersion",
        "minSdk = 24",
        text,
    )
    text = re.sub(
        r"minSdk\s*=\s*(?:2[0-3]|1\d)\b",
        "minSdk = 24",
        text,
    )
else:
    text = re.sub(
        r"minSdkVersion\s+flutter\.minSdkVersion",
        "minSdkVersion 24",
        text,
    )
    text = re.sub(
        r"minSdkVersion\s+(?:2[0-3]|1\d)\b",
        "minSdkVersion 24",
        text,
    )

if text == original:
    print(f"INFO: {target} already uses a compatible minSdk or a new template format.")
else:
    target.write_text(text, encoding="utf-8")
    print(f"UPDATED: {target} -> minSdk 24")

print("Android OCR SDK compatibility check complete.")
