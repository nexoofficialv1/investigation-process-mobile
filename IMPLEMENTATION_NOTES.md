# v1.7 Official CD Particulars + Case-tagged Forms Patch

Changes:

1. Case Diary PDF official layout corrected again:
   - `Particulars of Enquiry.` is now a single heading spanning the three marginal columns.
   - Below it, the three official marginal columns remain separate:
     - No. and hour of entry
     - Place of entry
     - Synopsis of entry
   - The right side proceedings/body column remains separate.
   - No horizontal line is inserted between individual CD entries.
   - Continued pages keep the official CD header and status row.

2. Forms section now has a case tagging / case selection dropdown:
   - IO can select which case the form belongs to before generating the form.
   - Saved forms are loaded case-wise for the selected case.

3. Auto-fill rules added:
   - 35(3) BNSS Notice auto-fills accused name from selected case.
   - 94 BNSS Notice auto-fills complainant/informant name from selected case.
   - IO can edit generated body before preview/export.

4. PDF + DOC export continues to be available through preview screen.

## v1.8 Case Parser Patch
- Added Case Parser dashboard module.
- Text parser supports structured police case text using labels: Ref, P.O, D.O, D.R, Complt, FIR Named Accd, I.O, Gist, Arrest.
- Extracted fields are shown in an editable review screen before saving.
- IO can create a new case or update an existing selected case.
- Camera/Scan Document button is reserved for the OCR phase; this patch keeps OCR as a safe placeholder and uses paste-text parsing first.
- Parsed data will feed Case Entry and later CD-I, forms, statements, final CD and IF5.
