#!/data/data/com.termux/files/usr/bin/bash
set -e

if [ ! -d .git ]; then
  echo "ERROR: এই script GitHub repository folder-এর ভিতরে চালান।"
  exit 1
fi

python apply_bangla_patch.py

git add .
git commit -m "Add full Bangla UI, documents and auto translation" || echo "নতুন commit করার মতো পরিবর্তন নেই।"
git push origin main

echo "Push সম্পন্ন। GitHub Actions খুলে Build Android APK run করুন।"
