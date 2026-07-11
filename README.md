# Investigation & Process Mobile MVP

Flutter Android MVP for police investigation workflow, CD writing, official forms, statement, reports, sketch map, PDF/DOC export and preview.

## v1.7 Update

- Official CD format corrected so `Particulars of Enquiry.` spans the three marginal cells and the entry columns remain separate.
- CD entries keep separate editable fields: Entry No/Time, Place of Entry, Synopsis of Entry and Proceedings.
- No line is drawn between individual CD entries.
- Forms module now supports selecting/tagging the case before generating forms.
- 35(3) Notice auto-fills accused name from selected case.
- 94 BNSS Notice auto-fills complainant name from selected case.
- IO can edit generated forms before preview and export.

## Build
Push to GitHub and use the included GitHub Actions workflow to build debug APK.
