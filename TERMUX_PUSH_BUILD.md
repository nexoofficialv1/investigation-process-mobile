# Termux Push Build - v3.2

```bash
cd /sdcard/Download
unzip -o investigation_process_mobile_mvp_v3_2_fsl_cdr_entry_pdf_fix.zip -d /sdcard/Download

cp -r lib investigation_process_mobile_mvp/
cp -r .github investigation_process_mobile_mvp/
cp -r backend_server investigation_process_mobile_mvp/ 2>/dev/null || true
cp -r web_app_server investigation_process_mobile_mvp/ 2>/dev/null || true
cp -f pubspec.yaml README.md IMPLEMENTATION_NOTES.md TERMUX_PUSH_BUILD.md ONLINE_BACKEND_PLAN.md push_to_github.sh investigation_process_mobile_mvp/ 2>/dev/null || true

cd /sdcard/Download/investigation_process_mobile_mvp
rm -f .github/workflows/build-apk.ymlyy

git add .
git commit -m "Fix FSL CDR structured entry and PDF preview overflow"
git push
```
