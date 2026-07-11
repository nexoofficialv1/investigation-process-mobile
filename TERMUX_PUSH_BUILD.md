# Termux থেকে GitHub Push + APK Build Guide

এই project ZIP Termux দিয়ে GitHub repo-তে push করলে GitHub Actions automatically debug APK build করবে।

## 1) Termux প্রস্তুত করুন

```bash
pkg update -y
pkg install git unzip nano -y
termux-setup-storage
```

## 2) ZIP Download folder-এ থাকলে unzip করুন

```bash
cd /sdcard/Download
unzip investigation_process_mobile_mvp_v0_3.zip
cd investigation_process_mobile_mvp
```

যদি ZIP-এর নাম আলাদা হয়, সেই নাম ব্যবহার করুন।

## 3) Git setup করুন

```bash
git config --global user.name "Kalna Police"
git config --global user.email "kalnapolice@gmail.com"
```

## 4) নতুন GitHub repo তৈরি করুন

GitHub app/browser থেকে নতুন public/private repo তৈরি করুন। Example repo name:

```text
investigation-process-mobile
```

Repo তৈরি করার সময় README, .gitignore, license add করবেন না। Empty repo রাখবেন।

## 5) Push করুন

`YOUR_REPO_URL`-এর জায়গায় আপনার repo URL বসান। Example:
`https://github.com/YOUR_USERNAME/investigation-process-mobile.git`

```bash
git init
git branch -M main
git add .
git commit -m "Initial Investigation Process Mobile MVP"
git remote add origin YOUR_REPO_URL
git push -u origin main
```

GitHub password চাইলে normal password দেবেন না। GitHub Personal Access Token দিতে হবে।

## 6) APK কোথায় পাবেন

GitHub repo → Actions → Build Android APK → latest run → Artifacts → `investigation-process-debug-apk` download করুন।

ZIP খুললে ভিতরে পাবেন:

```text
app-debug.apk
```

এই APK Android mobile-এ install করে test করা যাবে।

## 7) যদি push error আসে

Remote already exists:

```bash
git remote remove origin
git remote add origin YOUR_REPO_URL
git push -u origin main
```

Commit করার মতো কিছু নেই:

```bash
git status
git add .
git commit -m "Update Investigation Process Mobile MVP"
git push
```

Authentication fail হলে নতুন GitHub token তৈরি করে push করুন।
