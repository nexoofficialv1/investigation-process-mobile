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
    match = re.search(
        r'(?m)^(\s*)(?:release|getByName\("release"\))\s*\{',
        text,
    )
    if match is None:
        raise SystemExit("Release buildType not found in build.gradle.kts")
    block_start = match.end()
    block_end = text.find("\n" + match.group(1) + "}", block_start)
    if block_end < 0:
        raise SystemExit("Release buildType closing brace not found")
    block = text[block_start:block_end]
    indent = match.group(1) + "    "
    block = re.sub(
        r"(?m)^\s*isMinifyEnabled\s*=\s*(?:true|false)\s*$",
        "",
        block,
    )
    block = re.sub(
        r"(?m)^\s*isShrinkResources\s*=\s*(?:true|false)\s*$",
        "",
        block,
    )
    block = (
        "\n"
        + indent
        + "isMinifyEnabled = false\n"
        + indent
        + "isShrinkResources = false"
        + block
    )
    text = text[:block_start] + block + text[block_end:]
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
    match = re.search(r"(?m)^(\s*)release\s*\{", text)
    if match is None:
        raise SystemExit("Release buildType not found in build.gradle")
    block_start = match.end()
    block_end = text.find("\n" + match.group(1) + "}", block_start)
    if block_end < 0:
        raise SystemExit("Release buildType closing brace not found")
    block = text[block_start:block_end]
    indent = match.group(1) + "    "
    block = re.sub(
        r"(?m)^\s*minifyEnabled\s+(?:true|false)\s*$",
        "",
        block,
    )
    block = re.sub(
        r"(?m)^\s*shrinkResources\s+(?:true|false)\s*$",
        "",
        block,
    )
    block = (
        "\n"
        + indent
        + "minifyEnabled false\n"
        + indent
        + "shrinkResources false"
        + block
    )
    text = text[:block_start] + block + text[block_end:]

target.write_text(text, encoding="utf-8")
print(f"UPDATED: {target}")
print("OCR release configuration: minSdk 24; R8/minify OFF; resource shrink OFF.")
