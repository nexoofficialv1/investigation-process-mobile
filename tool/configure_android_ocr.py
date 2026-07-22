#!/usr/bin/env python3

from pathlib import Path
import re

candidates = [
    Path("android/app/build.gradle.kts"),
    Path("android/app/build.gradle"),
]

target = next((path for path in candidates if path.exists()), None)

if target is None:
    raise SystemExit(
        "Android Gradle file not found. "
        "Run this after: flutter create . --platforms=android"
    )

text = target.read_text(encoding="utf-8")
is_kotlin = target.suffix == ".kts"

# ML Kit / image_picker compatible minimum SDK.
if is_kotlin:
    text = re.sub(
        r"minSdk\s*=\s*flutter\.minSdkVersion",
        "minSdk = 24",
        text,
    )
    text = re.sub(
        r"minSdk\s*=\s*(?:1\d|2[0-3])\b",
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
        r"minSdkVersion\s+(?:1\d|2[0-3])\b",
        "minSdkVersion 24",
        text,
    )

# Connect the app-level ProGuard file to the release build.
has_proguard = (
    '"proguard-rules.pro"' in text
    or "'proguard-rules.pro'" in text
)

if not has_proguard:
    if is_kotlin:
        pattern = re.compile(
            r'(?m)^(\s*)(?:release|getByName\("release"\))\s*\{'
        )
        match = pattern.search(text)

        if match is None:
            raise SystemExit(
                "Release buildType not found in build.gradle.kts"
            )

        indent = match.group(1) + "    "
        addition = (
            match.group(0)
            + "\n"
            + indent
            + "proguardFiles(\n"
            + indent
            + '    getDefaultProguardFile('
              '"proguard-android-optimize.txt"),\n'
            + indent
            + '    "proguard-rules.pro",\n'
            + indent
            + ")\n"
        )
    else:
        pattern = re.compile(r"(?m)^(\s*)release\s*\{")
        match = pattern.search(text)

        if match is None:
            raise SystemExit(
                "Release buildType not found in build.gradle"
            )

        indent = match.group(1) + "    "
        addition = (
            match.group(0)
            + "\n"
            + indent
            + "proguardFiles "
              "getDefaultProguardFile("
              "'proguard-android-optimize.txt'), "
              "'proguard-rules.pro'\n"
        )

    text = text[:match.start()] + addition + text[match.end():]

target.write_text(text, encoding="utf-8")

rules_path = Path("android/app/proguard-rules.pro")
rules_path.parent.mkdir(parents=True, exist_ok=True)

marker = "# INVESTIGO ML Kit optional-script rules"
rules = """
# INVESTIGO ML Kit optional-script rules
# INVESTIGO currently uses TextRecognitionScript.latin only.
# These optional script implementations are intentionally not bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
""".strip()

existing = (
    rules_path.read_text(encoding="utf-8")
    if rules_path.exists()
    else ""
)

if marker not in existing:
    combined = existing.rstrip()
    if combined:
        combined += "\n\n"
    combined += rules + "\n"
    rules_path.write_text(combined, encoding="utf-8")

print(f"UPDATED: {target}")
print(f"UPDATED: {rules_path}")
print("ML Kit Latin OCR R8 configuration completed.")
