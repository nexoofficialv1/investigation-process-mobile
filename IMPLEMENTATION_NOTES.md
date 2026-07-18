# v3.4 FSL Simple Step-by-Step Entry Module

This patch improves FSL Form Fill Up usability without changing the official Form 5203 output format.

## Key Changes

- FSL form now has a simple step-by-step entry module.
- Pre-filled fields remain available from selected case and officer profile.
- Each official FSL point has a separate input area before preview/export.
- Exhibit entry is now row-based with one card per exhibit:
  - Label / Exhibit Mark
  - Description of exhibit
  - How and when found and by whom
  - Ownership of exhibit
  - Remarks (editable)
- Multiple exhibits can be added with “Add Exhibit”.
- Persons in custody now have one card per person:
  - Full name
  - Occupation
  - Age
  - Sex
  - Date & time of arrest
  - Bail/Custody status
  - Court
- Multiple persons in custody can be added with “Add Person”.
- The structured entry is converted into the existing official FSL package body before Preview/PDF/DOC export.

## Official Format Rule

The PDF/DOC output must keep the official West Bengal Form No. 5203 format. UI entry is simplified, but the final form layout should not be redesigned.

## v3.5 Miscellaneous Module
- Added a dashboard Miscellaneous card.
- Miscellaneous contains three tabs: Reports, Duty Column, and Inventory.
- Reports opens existing case-linked/general report generator.
- Duty Column stores date-wise duty type, staff/officer name, rank, duty point/place, time, mobile, and remarks; it supports Save, Preview, PDF export, and DOC export.
- Inventory stores item, category, quantity/balance stock, issued to, issue/return date, condition, and remarks; it supports Save, Preview, PDF export, and DOC export.
- Miscellaneous reports are kept separate from official case documents unless the report generator is linked to a case.


## v3.6 notes

The Forms module now contains a wider master registry for case forms, arrest/accused forms, UD forms, accident/MACT forms, and final documents. The Memo of Evidence template is generated from available case data and contains placeholders for investigation/CD/evidence-derived tables such as accused, seizure, 180/183 BNSS statements, medical, inquest/PM/FSL, evidence chart, and IO analysis. Further automation should map Investigation/Evidence/CD stored rows directly into these template rows.


## v3.7 Branding Patch
- App name changed to INVESTIGO.
- Splash/intro screen updated with animated professional investigation logo, subtitle and © Astra Technologies.
- Removed Dev: Bappa Roy from UI.
- Dashboard header/footer branding updated.
- Official generated documents remain clean without Astra Technologies footer.

## v3.9 CD Delete / CD Bundle / Manual Backup / PS Wording
- Added delete option for individual CDs from case detail screen with confirmation dialog.
- Added one-click CD 1 to 5 preview/share/export option when CD-1 to CD-5 are available.
- CD 1 to 5 bundle supports both PDF and DOC export through the existing Preview screen.
- Manual Backup screen wording updated to clearly show Manual Backup and Share Backup actions.
- App/UI/template strings updated to prefer “PS” instead of “Police Station”; official output keeps form structure unchanged.

## v4.0 — UD Official Package Patch

Added the uploaded UD templates into the UD Case module:

- West Bengal Form No. 5370 UD Final Report / PRB Form No. 53 vide Rule 276.
- Bengali Surathal Report narrative generator.
- West Bengal Form No. 5371 Dead Body Challan / PRB Form No. 54 vide Rule 252.
- Existing Inquest Form remains available.
- All outputs support Preview, PDF export/share and DOC export/share.
- New UD fields are saved inside the existing offline SharedPreferences UD draft store.
- Non-fixed UI wording uses PS instead of Police Station.

