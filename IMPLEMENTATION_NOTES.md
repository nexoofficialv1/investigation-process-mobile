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
