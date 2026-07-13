# Termux Push

```bash
cd /sdcard/Download
unzip -o investigation_process_mobile_mvp_v2_3_sketch_label_crash_fix.zip -d /sdcard/Download
cp -r lib investigation_process_mobile_mvp/
cp -r .github investigation_process_mobile_mvp/
cp -f pubspec.yaml README.md IMPLEMENTATION_NOTES.md TERMUX_PUSH_BUILD.md push_to_github.sh investigation_process_mobile_mvp/
cd /sdcard/Download/investigation_process_mobile_mvp
rm -f .github/workflows/build-apk.ymlyy
git add .
git commit -m "Fix sketch map label editor crash"
git push
```
