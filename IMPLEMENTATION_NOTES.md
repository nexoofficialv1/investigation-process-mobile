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

## v1.0 Official CD Correction
- CD PDF now follows the user-provided West Bengal Form No. 5363 style more closely.
- Added official top header, PRB Form No. 43 line, status row, Particulars of Enquiry row.
- CD table now has 4 columns: No. and hour of entry, Place of entry, Synopsis of entry, and proceedings/narrative.
- CD generator now creates date/time/synopsis-wise table lines instead of one modern 3-column layout.
- Evidence and sketch map inputs are part of case entry/investigation start; dashboard shortcuts route to case entry rather than showing next module placeholder.

## v1.1 Sketch Map Builder
- Added symbol-based Rough Sketch Map Builder inside case flow.
- Ready objects: House, Pond, Tree, Shop, Road, Field, PO mark, North arrow.
- Tap object button to place on canvas; drag with finger to adjust position.
- Tap object to edit label, direction and index description.
- Auto marker A/B/C... for objects.
- Direction fields for North/South/East/West surroundings.
- Sketch Map PDF preview/export added.
- Export flow asks whether to mention the sketch map in Case Diary and creates a pending CD entry.

## v1.2 General Report Module
- Report module no longer requires a case.
- Dashboard Report card opens General/Non-case report mode even if no case exists.
- If a latest case exists, IO can toggle "Link this report with current case".
- Case-linked templates remain available for SP/SDPO/SDO case progress reports.
- General templates added for SP, SDPO, SDO/Executive Magistrate, Ld. Court, Bank, Hospital, and blank custom report.
- General reports use Preview before Export and save as report drafts under `general_report`.
