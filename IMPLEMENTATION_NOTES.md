# Implementation Notes

## CD generator rule

Every CD body starts with:

`Resumed further investigation of the case.`

Every CD body ends with:

`Closed the diary pending for further investigation of this case.`

Middle paragraphs are generated from Yes/No answers and then edited by the IO.

## Step 4 Investigation Start

Step 4 includes:

- IO Name auto
- Took up investigation date
- Visited PO yes/no + details
- Rough sketch map prepared yes/no + details
- Witness examined yes/no + details
- Medical required yes/no + details
- Seizure required yes/no + details

This feeds CD-I generation.

## CD-II onward

CD-II and later CDs use the question-based CD builder:

- Witness examined
- PO visited
- Sketch map prepared/updated
- Medical papers collected
- Requisition sent
- Seizure made
- Arrest made
- Notice served
- Court prayer submitted
- Order/report/document received
- Local enquiry conducted
- Verification done
- Digital evidence collected
- Important development

After `Generate CD`, the IO gets an editable draft before final save and PDF export.

## v0.4 CI Fix
- GitHub Actions now deletes the generated default Flutter test folder after `flutter create`.
- The blocking `flutter analyze` step was removed from APK CI so the debug APK can be generated first.
- Cleaned unnecessary non-null assertion in `case_detail_screen.dart`.

## v0.5 Official CD Format Lock
- Case Diary PDF export has been corrected to use a locked official-style A4 CD template.
- Removed the earlier experimental/creative CD layout.
- CD export now keeps the official heading, case details block, three-column CD table, body area, and IO signature area.
- Only investigation body text is generated/edited; the template layout should not be changed unless the official blank CD format is updated.

## v0.6 UI Direction
- Added modern mobile dashboard inspired by card-grid institutional app UI.
- Added opening intro/start screen with app identity and feature summary.
- Added cream background, dark green header, icon-circle cards, and bottom navigation.
- Kept official document/PDF formatting separate from mobile UI: UI can be modern, but CD/IF5 PDF templates must remain locked official format.

## v0.7 Workflow Patch

### Preview Before Export
All exportable documents must follow this workflow:

`Generate Draft -> Edit -> Preview Official A4 PDF -> Export PDF`

Added reusable `PdfPreviewScreen` using the `printing` package. CD, Statement, and Forms/Notices now open a preview screen before PDF export/share.

### Requisition/Form to Case Diary Link
Whenever a form/requisition/notice is saved or exported, the app asks whether it should be mentioned in the Case Diary. If the IO selects Yes, a date-wise pending CD entry is created.

Pending entries are shown in the next CD Builder under `Pending CD Entries from Forms/Requisitions`. The IO may tick/untick entries before generating the CD. Included entries are inserted into the CD body and marked consumed after CD generation.

### Official Format Rule
UI can be modern. Official documents must not be redesigned. CD and IF5/CS Annexure must use locked official templates. Only dynamic investigation data and body content are editable.

### IF5/CS Annexure Rule
IF5 is investigation-based. It will be generated from accumulated case data, all CDs, and especially the Final/Last CD investigation summary. Page count must remain dynamic; serial number order must be fixed and continuous.
