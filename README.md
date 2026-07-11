# Investigation & Process Mobile MVP v0.2

Mobile-first Flutter MVP for an IO-focused Investigation & Process app.

## Current MVP modules

- Officer profile with PS, district and court defaults
- Case create/edit flow
- Step 4 Investigation Start with conditional Yes/No detail fields
- Case dashboard and case detail screen
- Question-based CD generator for CD-I / CD-II onward
- Fixed CD opening line: `Resumed further investigation of the case.`
- Fixed CD closing line: `Closed the diary pending for further investigation of this case.`
- Editable generated CD draft
- Draft save / final save / A4 PDF export for Case Diary
- Statement module with basic draft, save and PDF export
- Forms & Notices module with auto-filled templates, edit, draft save, final save and PDF export
- Forms included: 35(3) BNSS, 94 BNSS, 183 BNSS, Medical, BHT/Injury, CDR/CAF, Bank requisition, FSL, Forwarding, Further Investigation Prayer, CS/FR checklist
- Compliance checklist with section-based prompts
- Local storage through SharedPreferences for MVP simplicity
- GitHub Actions workflow to build debug APK

## Important production notes

This is a source-code MVP starter, not a compiled production APK.

For production, replace SharedPreferences with encrypted SQLite/Drift/Isar and add:

- PIN / biometric app lock
- Encrypted backup and restore
- Bengali Unicode PDF font support
- Case-wise attachment storage
- Sketch map builder
- CS/IF5 full layout
- Cloud sync through Supabase/Firebase
- Audit log
- AI drafting assistance only after stable offline MVP

## Local build

```bash
flutter create . --platforms=android
flutter pub get
flutter build apk --debug
```

## GitHub Actions APK build

1. Create a GitHub repository.
2. Upload/push this folder to the repo.
3. Open the Actions tab.
4. Run `Build Android APK` workflow.
5. Download `investigation-process-debug-apk` artifact.

## Bengali PDF support

The PDF template currently uses default PDF fonts for maximum portability. For Bengali body text PDF export, add a Unicode Bengali font in assets and load it in `PdfService`.

## Architecture summary

`Flutter Mobile App -> Local Store -> CD/Forms/Statement Generators -> A4 PDF Engine -> GitHub Actions APK Build`

## v0.3 Push/Build Ready

Added Termux push guide and helper script:

- `TERMUX_PUSH_BUILD.md`
- `push_to_github.sh`

After pushing to GitHub, the included workflow `.github/workflows/android-apk.yml` will generate Android platform files and build a debug APK.


## v0.7 Added Workflow

- Mandatory preview before PDF export for CD, Statement and Forms/Notices.
- Form/Requisition save/export now asks: “Do you want to mention this in the Case Diary?”
- If Yes, app creates a date-wise pending CD entry.
- CD Builder displays pending form/requisition entries so IO can include/edit them in the daily CD.
- Official output templates remain locked; app UI may be modern but PDF formats must remain official.
